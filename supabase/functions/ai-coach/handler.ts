// AI 코치 요청 처리. 외부 의존성(인증, DB, 모델)은 Deps로 주입받아 테스트에서 바꿔 끼운다.
//
// 요청:  POST { pet_id, messages: [{role, content}], locale: ko|en|ja, utc_offset_minutes }
// 응답:  text/event-stream, 줄마다 `data: {json}`
//   {type:"meta", used, limit, records}      한도 차감 후 첫 이벤트
//   {type:"delta", text}                      답변 조각
//   {type:"refs", refs:[{id, recorded_at}]}   답변이 근거로 쓴 기록
//   {type:"done", stop_reason}
//   {type:"error", code}                      스트림 도중 실패 (refused | model_error)
// 스트림 전 실패는 JSON {error: code}와 상태 코드로 돌려준다.

import type { ChatTurn, ModelClient, ModelEvent } from "./model.ts";
import { buildContext, extractRefs, normalizeLocale, type PetRow, type RecordRow } from "./prompt.ts";

export interface Deps {
  /** Authorization 헤더로 사용자 확인. 실패하면 null */
  getUserId(authHeader: string): Promise<string | null>;
  /** 사용자 권한(RLS)으로 펫과 최근 기록, 동의 여부를 읽는다. 펫에 접근할 수 없으면 pet = null */
  loadContext(authHeader: string, petId: string, since: Date): Promise<{
    consented: boolean;
    pet: PetRow | null;
    records: RecordRow[];
  }>;
  consumeQuota(userId: string, offsetMinutes: number): Promise<{ allowed: boolean; used: number; limit: number }>;
  refundQuota(userId: string, offsetMinutes: number): Promise<void>;
  logUsage(row: Record<string, unknown>): Promise<void>;
  model: ModelClient | null;
  now(): Date;
}

const MAX_TURNS = 20;
const MAX_CHARS = 4000;
const CONTEXT_DAYS = 14;
const MAX_RECORDS = 150;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function parseBody(raw: unknown): {
  petId: string;
  messages: ChatTurn[];
  locale: ReturnType<typeof normalizeLocale>;
  offset: number;
} | null {
  if (!raw || typeof raw !== "object") return null;
  const b = raw as Record<string, unknown>;
  if (typeof b.pet_id !== "string" || !/^[0-9a-f-]{36}$/i.test(b.pet_id)) return null;
  if (!Array.isArray(b.messages) || b.messages.length === 0 || b.messages.length > MAX_TURNS) return null;
  const messages: ChatTurn[] = [];
  for (const m of b.messages) {
    if (!m || typeof m !== "object") return null;
    const { role, content } = m as Record<string, unknown>;
    if ((role !== "user" && role !== "assistant") || typeof content !== "string") return null;
    const text = content.trim();
    if (!text || text.length > MAX_CHARS) return null;
    messages.push({ role, content: text });
  }
  // 첫 턴과 마지막 턴은 사용자여야 하고, 역할이 번갈아 나와야 한다
  if (messages[0].role !== "user" || messages.at(-1)!.role !== "user") return null;
  for (let i = 1; i < messages.length; i++) {
    if (messages[i].role === messages[i - 1].role) return null;
  }
  const offset = Number.isInteger(b.utc_offset_minutes) ? Math.max(-840, Math.min(840, b.utc_offset_minutes as number)) : 540;
  return { petId: b.pet_id, messages, locale: normalizeLocale(b.locale), offset };
}

export async function handleRequest(req: Request, deps: Deps): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const auth = req.headers.get("Authorization");
  if (!auth) return json(401, { error: "unauthorized" });
  const userId = await deps.getUserId(auth);
  if (!userId) return json(401, { error: "unauthorized" });

  let body: ReturnType<typeof parseBody>;
  try {
    body = parseBody(await req.json());
  } catch {
    body = null;
  }
  if (!body) return json(400, { error: "bad_request" });

  if (!deps.model) return json(503, { error: "ai_unavailable" });

  const now = deps.now();
  const since = new Date(now.getTime() - CONTEXT_DAYS * 24 * 3600_000);
  const ctx = await deps.loadContext(auth, body.petId, since);
  if (!ctx.consented) return json(403, { error: "consent_required" });
  if (!ctx.pet) return json(404, { error: "pet_not_found" });

  const quota = await deps.consumeQuota(userId, body.offset);
  if (!quota.allowed) return json(429, { error: "quota_exceeded", used: quota.used, limit: quota.limit });

  const records = ctx.records.slice(0, MAX_RECORDS);
  const built = buildContext(ctx.pet, records, body.locale, body.offset, now);
  const model = deps.model;
  const encoder = new TextEncoder();
  const offset = body.offset;
  const petId = body.petId;

  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (event: Record<string, unknown>) =>
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(event)}\n\n`));

      send({ type: "meta", used: quota.used, limit: quota.limit, records: records.length });

      let reply = "";
      let done: Extract<ModelEvent, { type: "done" }> | null = null;
      let error: string | null = null;
      try {
        for await (const ev of model.stream({ context: built.text, messages: body!.messages, locale: body!.locale })) {
          if (ev.type === "text") {
            reply += ev.text;
            send({ type: "delta", text: ev.text });
          } else {
            done = ev;
          }
        }
      } catch (e) {
        error = e instanceof Error ? e.message : String(e);
      }

      if (error || !done) {
        // 답변이 시작되기 전에 실패했으면 차감한 1회를 돌려준다
        if (!reply) await deps.refundQuota(userId, offset).catch(() => {});
        send({ type: "error", code: "model_error" });
      } else if (done.stopReason === "refusal") {
        // 폴백 모델까지 모두 거절. 도중까지 받은 답은 완성된 답이 아니므로 앱이 버린다
        send({ type: "error", code: "refused" });
      } else {
        const { refs } = extractRefs(reply, built.refIndex);
        send({ type: "refs", refs: refs.map((r) => ({ id: r.id, recorded_at: r.recorded_at })) });
        send({ type: "done", stop_reason: done.stopReason });
      }

      await deps.logUsage({
        user_id: userId,
        pet_id: petId,
        model: done?.model ?? null,
        input_tokens: done?.usage.input_tokens ?? null,
        output_tokens: done?.usage.output_tokens ?? null,
        cache_read_input_tokens: done?.usage.cache_read_input_tokens ?? null,
        cache_creation_input_tokens: done?.usage.cache_creation_input_tokens ?? null,
        stop_reason: done?.stopReason ?? null,
        fallback_used: done?.fallbackUsed ?? false,
        fake: model.fake,
        error: error?.slice(0, 500) ?? null,
      }).catch(() => {});
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      ...corsHeaders,
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache",
    },
  });
}
