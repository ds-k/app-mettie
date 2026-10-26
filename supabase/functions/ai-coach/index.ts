// AI 코치 Edge Function 진입점: Supabase 클라이언트와 모델을 연결한다.
//
// 시크릿
//   ANTHROPIC_API_KEY  Claude API 키 (supabase secrets set)
//   AI_COACH_FAKE=1    키 없이 개발할 때만. 가짜 응답으로 전체 흐름을 시험한다
// Supabase가 자동으로 넣는 값: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "npm:@supabase/supabase-js@2.118.0";

import { type Deps, handleRequest } from "./handler.ts";
import { anthropicModel, fakeModel, type ModelClient } from "./model.ts";
import type { PetRow, RecordRow } from "./prompt.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const service = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

function selectModel(): ModelClient | null {
  if (Deno.env.get("AI_COACH_FAKE") === "1") return fakeModel();
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  return key ? anthropicModel(key) : null;
}

const PET_COLUMNS =
  "id,name,species,breed,sex,is_neutered,date_of_birth,diagnosis,diagnosed_at,insulin_type,insulin_unit_iu," +
  "insulin_concentration,syringe_type,dosing_times,target_glucose_min,target_glucose_max,hypo_threshold," +
  "glucose_meter,weight_kg";
const RECORD_COLUMNS =
  "id,recorded_at,glucose_value,glucose_type,insulin_dose,insulin_type,injection_status,food_type,food_brand," +
  "food_amount_g,appetite,weight_kg,water_intake,urination,vomit_count,stool_status,symptom_tags,notes";

const deps: Deps = {
  async getUserId(authHeader) {
    const { data, error } = await service.auth.getUser(authHeader.replace(/^Bearer\s+/i, ""));
    return error || !data.user ? null : data.user.id;
  },

  async loadContext(authHeader, petId, since) {
    // 사용자 토큰으로 읽어 RLS가 가족 범위를 강제하게 한다
    const asUser = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });
    const [status, pet, records] = await Promise.all([
      asUser.rpc("ai_quota_status", { p_offset_minutes: 0 }).single(),
      asUser.from("pets").select(PET_COLUMNS).eq("id", petId).maybeSingle(),
      asUser.from("records").select(RECORD_COLUMNS).eq("pet_id", petId)
        .gte("recorded_at", since.toISOString())
        .order("recorded_at", { ascending: false })
        .limit(150),
    ]);
    return {
      consented: (status.data as { consented?: boolean } | null)?.consented === true,
      pet: (pet.data as PetRow | null) ?? null,
      records: (records.data as RecordRow[] | null) ?? [],
    };
  },

  async consumeQuota(userId, offsetMinutes) {
    const { data, error } = await service.rpc("consume_ai_quota", {
      p_user: userId,
      p_offset_minutes: offsetMinutes,
    }).single();
    if (error || !data) throw error ?? new Error("consume_ai_quota failed");
    const row = data as { allowed: boolean; used: number; daily_limit: number };
    return { allowed: row.allowed, used: row.used, limit: row.daily_limit };
  },

  async refundQuota(userId, offsetMinutes) {
    const { error } = await service.rpc("refund_ai_quota", { p_user: userId, p_offset_minutes: offsetMinutes });
    if (error) console.error("refund_ai_quota failed", error);
  },

  async logUsage(row) {
    const { error } = await service.from("ai_usage_log").insert(row);
    if (error) console.error("ai_usage_log insert failed", error);
  },

  model: selectModel(),
  now: () => new Date(),
};

Deno.serve((req) => handleRequest(req, deps));
