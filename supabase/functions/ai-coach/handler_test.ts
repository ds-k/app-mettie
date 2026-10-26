// deno test supabase/functions/ai-coach
import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@1";

import { type Deps, handleRequest, parseBody } from "./handler.ts";
import { fakeModel, type ModelClient } from "./model.ts";
import { buildContext, extractRefs, type PetRow, type RecordRow, STATIC_SYSTEM } from "./prompt.ts";

const PET: PetRow = {
  id: "e1000000-0000-0000-0000-000000000001",
  name: "Coco",
  species: "cat",
  breed: null,
  sex: "male",
  is_neutered: true,
  date_of_birth: null,
  diagnosis: "당뇨",
  diagnosed_at: null,
  insulin_type: "란투스(Lantus)",
  insulin_unit_iu: 2,
  insulin_concentration: "U-100",
  syringe_type: "U-100",
  dosing_times: ["07:00:00", "19:00:00"],
  target_glucose_min: 100,
  target_glucose_max: 300,
  hypo_threshold: 80,
  glucose_meter: null,
  weight_kg: 4.8,
};

function record(id: string, iso: string, extra: Partial<RecordRow>): RecordRow {
  return {
    id, recorded_at: iso, glucose_value: null, glucose_type: null, insulin_dose: null, insulin_type: null,
    injection_status: null, food_type: null, food_brand: null, food_amount_g: null, appetite: null, weight_kg: null,
    water_intake: null, urination: null, vomit_count: null, stool_status: null, symptom_tags: null, notes: null,
    ...extra,
  };
}

const RECORDS = [
  record("rec-new", "2026-10-26T09:49:00Z", { glucose_value: 215, glucose_type: "pre_meal" }),
  record("rec-old", "2026-10-22T04:00:00Z", { glucose_value: 72, glucose_type: "nadir", symptom_tags: ["lethargy"] }),
];

function deps(over: Partial<Deps> = {}): Deps & { calls: Record<string, unknown[]> } {
  const calls: Record<string, unknown[]> = { refund: [], log: [], consume: [] };
  return {
    calls,
    getUserId: () => Promise.resolve("user-1"),
    loadContext: () => Promise.resolve({ consented: true, pet: PET, records: RECORDS }),
    consumeQuota: (u, o) => {
      calls.consume.push([u, o]);
      return Promise.resolve({ allowed: true, used: 3, limit: 10 });
    },
    refundQuota: (u) => {
      calls.refund.push(u);
      return Promise.resolve();
    },
    logUsage: (row) => {
      calls.log.push(row);
      return Promise.resolve();
    },
    model: fakeModel(0),
    now: () => new Date("2026-10-26T11:00:00Z"),
    ...over,
  };
}

function request(body: unknown, auth = "Bearer token"): Request {
  return new Request("http://localhost/ai-coach", {
    method: "POST",
    headers: { Authorization: auth, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

const VALID = {
  pet_id: PET.id,
  messages: [{ role: "user", content: "이번 주 혈당 어때?" }],
  locale: "ko",
  utc_offset_minutes: 540,
};

async function events(res: Response): Promise<Record<string, unknown>[]> {
  const text = await res.text();
  return text.split("\n\n").filter((l) => l.startsWith("data: ")).map((l) => JSON.parse(l.slice(6)));
}

Deno.test("정상 흐름: meta → delta… → refs → done, 근거 기록을 돌려주고 사용량을 기록한다", async () => {
  const d = deps();
  const res = await handleRequest(request(VALID), d);
  assertEquals(res.status, 200);
  assertStringIncludes(res.headers.get("Content-Type")!, "text/event-stream");
  const evs = await events(res);
  assertEquals(evs[0], { type: "meta", used: 3, limit: 10, records: 2 });
  assert(evs.some((e) => e.type === "delta"));
  const refs = evs.find((e) => e.type === "refs") as { refs: { id: string }[] };
  assertEquals(refs.refs.map((r) => r.id), ["rec-new"]);
  assertEquals(evs.at(-1)!.type, "done");
  assertEquals(d.calls.log.length, 1);
  assertEquals((d.calls.log[0] as { fake: boolean }).fake, true);
  assertEquals(d.calls.consume, [["user-1", 540]]);
});

Deno.test("동의하지 않았으면 403, 한도는 차감하지 않는다", async () => {
  const d = deps({ loadContext: () => Promise.resolve({ consented: false, pet: PET, records: [] }) });
  const res = await handleRequest(request(VALID), d);
  assertEquals(res.status, 403);
  assertEquals((await res.json()).error, "consent_required");
  assertEquals(d.calls.consume.length, 0);
});

Deno.test("접근할 수 없는 펫은 404", async () => {
  const res = await handleRequest(request(VALID), deps({
    loadContext: () => Promise.resolve({ consented: true, pet: null, records: [] }),
  }));
  assertEquals(res.status, 404);
});

Deno.test("한도를 넘으면 429와 사용량", async () => {
  const res = await handleRequest(request(VALID), deps({
    consumeQuota: () => Promise.resolve({ allowed: false, used: 10, limit: 10 }),
  }));
  assertEquals(res.status, 429);
  assertEquals(await res.json(), { error: "quota_exceeded", used: 10, limit: 10 });
});

Deno.test("인증 실패 401, 모델 미설정 503", async () => {
  assertEquals((await handleRequest(request(VALID), deps({ getUserId: () => Promise.resolve(null) }))).status, 401);
  assertEquals((await handleRequest(request(VALID), deps({ model: null }))).status, 503);
});

Deno.test("응답 전에 모델이 실패하면 차감한 1회를 환불한다", async () => {
  const broken: ModelClient = {
    fake: false,
    // deno-lint-ignore require-yield
    async *stream() {
      throw new Error("overloaded");
    },
  };
  const d = deps({ model: broken });
  const evs = await events(await handleRequest(request(VALID), d));
  assertEquals(evs.at(-1), { type: "error", code: "model_error" });
  assertEquals(d.calls.refund, ["user-1"]);
});

Deno.test("모든 모델이 거절하면 refused, 환불하지 않는다", async () => {
  const refusing: ModelClient = {
    fake: false,
    async *stream() {
      yield { type: "text", text: "부분" };
      yield {
        type: "done", model: "m", stopReason: "refusal", fallbackUsed: true,
        usage: { input_tokens: 1, output_tokens: 1, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 },
      };
    },
  };
  const d = deps({ model: refusing });
  const evs = await events(await handleRequest(request(VALID), d));
  assertEquals(evs.at(-1), { type: "error", code: "refused" });
  assertEquals(d.calls.refund.length, 0);
});

Deno.test("요청 검증: 역할 순서, 길이, pet_id 형식", () => {
  assert(parseBody(VALID));
  assertEquals(parseBody({ ...VALID, pet_id: "x" }), null);
  assertEquals(parseBody({ ...VALID, messages: [{ role: "assistant", content: "hi" }] }), null);
  assertEquals(parseBody({ ...VALID, messages: [{ role: "user", content: "a" }, { role: "user", content: "b" }] }), null);
  assertEquals(parseBody({ ...VALID, messages: [{ role: "user", content: "x".repeat(4001) }] }), null);
  assertEquals(parseBody({ ...VALID, utc_offset_minutes: 9999 })!.offset, 840);
  assertEquals(parseBody({ ...VALID, locale: "fr" })!.locale, "ko");
});

Deno.test("고정 지시문에는 펫·시각·언어가 섞이지 않아 캐시가 유지된다", () => {
  assert(!STATIC_SYSTEM.includes("Coco"));
  assert(!/20\d\d-\d\d-\d\d/.test(STATIC_SYSTEM));
  // Opus 5.5 캐싱 최소 길이(512토큰)를 여유 있게 넘는지 대략 확인 (영어 1토큰 ≈ 4자).
  // 짧아지면 캐시가 조용히 꺼진다. 실제 값은 응답 usage.cache_read_input_tokens로 확인한다.
  assert(STATIC_SYSTEM.length / 4 > 800);
});

Deno.test("컨텍스트: 기기 시간대로 시각을 쓰고 언어를 지정한다", () => {
  const ctx = buildContext(PET, RECORDS, "ja", 540, new Date("2026-10-26T11:00:00Z"));
  assertStringIncludes(ctx.text, "Reply in Japanese.");
  assertStringIncludes(ctx.text, "R1 | 2026-10-26 18:49 | glucose 215 mg/dL (pre_meal)");
  assertStringIncludes(ctx.text, "R2 | 2026-10-22 13:00 | glucose 72 mg/dL (nadir); signs: lethargy");
  assertStringIncludes(ctx.text, "hypoglycemia below 80");
});

Deno.test("근거 표시를 떼어 내고 없는 ID는 무시한다", () => {
  const ctx = buildContext(PET, RECORDS, "ko", 540, new Date());
  const { text, refs } = extractRefs("내려가는 추세예요.\n\n[[refs: R2, R9]]", ctx.refIndex);
  assertEquals(text, "내려가는 추세예요.");
  assertEquals(refs.map((r) => r.id), ["rec-old"]);
  assertEquals(extractRefs("근거 없음", ctx.refIndex).refs, []);
});
