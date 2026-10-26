-- AI 코치 API 전환 (v1.1.0)
-- - 제3자(Anthropic) 전송 동의 기록
-- - 가족 단위 요금제와 사용자별 하루 요청 한도
-- - 앱 설정(한도, 최소 지원 버전)과 비용 추정용 토큰 로그

-- ─── 동의 ─────────────────────────────────────────────────────────────────────
ALTER TABLE "public"."users"
  ADD COLUMN IF NOT EXISTS "ai_consent_at" timestamptz;

-- 본인 동의 기록. 동의를 철회하면 null로 되돌린다.
CREATE OR REPLACE FUNCTION "public"."set_ai_consent"("p_consent" boolean)
RETURNS timestamptz
    LANGUAGE sql SECURITY DEFINER SET search_path = ''
    AS $$
  UPDATE public.users
  SET ai_consent_at = CASE WHEN p_consent THEN now() ELSE NULL END
  WHERE id = auth.uid()
  RETURNING ai_consent_at;
$$;
REVOKE ALL ON FUNCTION "public"."set_ai_consent"(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION "public"."set_ai_consent"(boolean) TO authenticated;

-- ─── 요금제 (가족 단위, 결제는 이후 RevenueCat 웹훅이 갱신) ────────────────────
ALTER TABLE "public"."families"
  ADD COLUMN IF NOT EXISTS "pro_until" timestamptz;

-- ─── 앱 설정 ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "public"."app_config" (
  "key" text PRIMARY KEY,
  "value" jsonb NOT NULL,
  "updated_at" timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;
-- 로그인 전(강제 업데이트 확인)에도 읽을 수 있어야 한다. 쓰기는 대시보드/서비스 키로만.
DROP POLICY IF EXISTS "Anyone can read app config" ON "public"."app_config";
CREATE POLICY "Anyone can read app config" ON "public"."app_config"
  FOR SELECT TO anon, authenticated USING (true);
GRANT SELECT ON "public"."app_config" TO anon, authenticated;

INSERT INTO "public"."app_config" ("key", "value") VALUES
  ('ai_daily_limit_free', '10'),
  ('ai_daily_limit_pro', '100'),
  ('min_supported_version', '"1.0.0"')
ON CONFLICT ("key") DO NOTHING;

-- ─── 사용량 ──────────────────────────────────────────────────────────────────
-- 사용자 기준 하루(사용자 기기의 UTC 오프셋으로 자른 날짜) 요청 수
CREATE TABLE IF NOT EXISTS "public"."ai_usage" (
  "user_id" uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  "day" date NOT NULL,
  "count" integer NOT NULL DEFAULT 0,
  PRIMARY KEY ("user_id", "day")
);
ALTER TABLE "public"."ai_usage" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own ai usage" ON "public"."ai_usage";
CREATE POLICY "Users can read own ai usage" ON "public"."ai_usage"
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- 비용 추정용 호출 로그. 클라이언트는 접근하지 않는다 (정책 없음 = 서비스 키만)
CREATE TABLE IF NOT EXISTS "public"."ai_usage_log" (
  "id" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "user_id" uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  "pet_id" uuid REFERENCES public.pets(id) ON DELETE SET NULL,
  "model" text,
  "input_tokens" integer,
  "output_tokens" integer,
  "cache_read_input_tokens" integer,
  "cache_creation_input_tokens" integer,
  "stop_reason" text,
  "fallback_used" boolean NOT NULL DEFAULT false,
  "fake" boolean NOT NULL DEFAULT false,
  "error" text
);
ALTER TABLE "public"."ai_usage_log" ENABLE ROW LEVEL SECURITY;

-- 이 프로젝트는 새 테이블에 기본 권한을 주지 않으므로(baseline의 ALTER DEFAULT PRIVILEGES) 필요한 것만 명시한다
GRANT SELECT ON "public"."ai_usage" TO authenticated;
GRANT SELECT, INSERT ON "public"."ai_usage_log" TO service_role;

-- 사용자의 요금제: 속한 가족 중 하나라도 Pro면 Pro
CREATE OR REPLACE FUNCTION "public"."ai_daily_limit"("p_user" uuid)
RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
    AS $$
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM public.user_families uf
      JOIN public.families f ON f.id = uf.family_id
      WHERE uf.user_id = p_user AND f.pro_until IS NOT NULL AND f.pro_until > now()
    )
    THEN (SELECT (value #>> '{}')::int FROM public.app_config WHERE key = 'ai_daily_limit_pro')
    ELSE (SELECT (value #>> '{}')::int FROM public.app_config WHERE key = 'ai_daily_limit_free')
  END;
$$;
REVOKE ALL ON FUNCTION "public"."ai_daily_limit"(uuid) FROM PUBLIC, anon, authenticated;

-- 오프셋(분)을 -14h~+14h로 제한해 사용자 기준 날짜를 구한다
CREATE OR REPLACE FUNCTION "public"."ai_local_day"("p_offset_minutes" integer)
RETURNS date
    LANGUAGE sql STABLE SET search_path = ''
    AS $$
  SELECT ((now() AT TIME ZONE 'UTC') + make_interval(mins => greatest(-840, least(840, coalesce(p_offset_minutes, 540)))))::date;
$$;

-- 앱 화면용: 오늘 사용량과 한도
CREATE OR REPLACE FUNCTION "public"."ai_quota_status"("p_offset_minutes" integer)
RETURNS TABLE ("used" integer, "daily_limit" integer, "consented" boolean)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
    AS $$
  SELECT
    coalesce((SELECT count FROM public.ai_usage
              WHERE user_id = auth.uid() AND day = public.ai_local_day(p_offset_minutes)), 0),
    public.ai_daily_limit(auth.uid()),
    (SELECT ai_consent_at IS NOT NULL FROM public.users WHERE id = auth.uid());
$$;
REVOKE ALL ON FUNCTION "public"."ai_quota_status"(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION "public"."ai_quota_status"(integer) TO authenticated;

-- 서버 함수용: 한도 안이면 1 차감하고 사용량을 돌려준다. 한도를 넘으면 allowed = false.
-- 동시에 여러 요청이 와도 한도를 넘지 않도록 한 문장(INSERT ... ON CONFLICT ... WHERE)으로 처리한다.
CREATE OR REPLACE FUNCTION "public"."consume_ai_quota"("p_user" uuid, "p_offset_minutes" integer)
RETURNS TABLE ("allowed" boolean, "used" integer, "daily_limit" integer)
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
    AS $$
DECLARE
  v_limit integer := public.ai_daily_limit(p_user);
  v_day date := public.ai_local_day(p_offset_minutes);
  v_count integer;
BEGIN
  IF coalesce(v_limit, 0) <= 0 THEN
    RETURN QUERY SELECT false, 0, coalesce(v_limit, 0);
    RETURN;
  END IF;

  INSERT INTO public.ai_usage AS u (user_id, day, count)
  VALUES (p_user, v_day, 1)
  ON CONFLICT (user_id, day) DO UPDATE SET count = u.count + 1
    WHERE u.count < v_limit
  RETURNING u.count INTO v_count;

  IF v_count IS NULL OR v_count > v_limit THEN
    RETURN QUERY SELECT false, coalesce((SELECT count FROM public.ai_usage WHERE user_id = p_user AND day = v_day), 0), v_limit;
  ELSE
    RETURN QUERY SELECT true, v_count, v_limit;
  END IF;
END;
$$;

-- 서버 함수용: 모델 호출이 응답 전에 실패하면 차감한 1회를 돌려준다
CREATE OR REPLACE FUNCTION "public"."refund_ai_quota"("p_user" uuid, "p_offset_minutes" integer)
RETURNS void
    LANGUAGE sql SECURITY DEFINER SET search_path = ''
    AS $$
  UPDATE public.ai_usage SET count = greatest(0, count - 1)
  WHERE user_id = p_user AND day = public.ai_local_day(p_offset_minutes);
$$;

REVOKE ALL ON FUNCTION "public"."consume_ai_quota"(uuid, integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION "public"."refund_ai_quota"(uuid, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION "public"."consume_ai_quota"(uuid, integer) TO service_role;
GRANT EXECUTE ON FUNCTION "public"."refund_ai_quota"(uuid, integer) TO service_role;
