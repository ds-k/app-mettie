-- 당뇨 관리 계획 필드와 가족 간 중복 투여 차단 함수 (v1.1.0)

-- ─── 관리 계획 ───────────────────────────────────────────────────────────────
ALTER TABLE "public"."pets"
  -- 켜진 질환 모듈. 홈과 건강수첩이 이 목록으로 카드를 구성한다 (v1.1.0은 'diabetes'만)
  ADD COLUMN IF NOT EXISTS "conditions" text[] NOT NULL DEFAULT '{}',
  -- 투여 시각 (예: {07:00,19:00}). 다음 투여 카드, 중복 판정, 투여 알림의 기준
  ADD COLUMN IF NOT EXISTS "dosing_times" time[] NOT NULL DEFAULT '{}',
  -- 인슐린 농도와 주사기. U-40/U-100 혼동은 반려동물 인슐린 사고의 대표 원인
  ADD COLUMN IF NOT EXISTS "insulin_concentration" text
    CHECK ("insulin_concentration" IN ('U-40', 'U-100', 'U-300')),
  ADD COLUMN IF NOT EXISTS "syringe_type" text
    CHECK ("syringe_type" IN ('U-40', 'U-100', 'pen')),
  ADD COLUMN IF NOT EXISTS "hypo_threshold" integer NOT NULL DEFAULT 80
    CHECK ("hypo_threshold" BETWEEN 40 AND 150),
  ADD COLUMN IF NOT EXISTS "glucose_meter" text,
  ADD COLUMN IF NOT EXISTS "default_food_wet" text,
  ADD COLUMN IF NOT EXISTS "default_food_dry" text;

-- 기존 펫: 당뇨 진단이나 인슐린 정보가 있으면 당뇨 모듈을 켠다
UPDATE "public"."pets"
SET "conditions" = array_append("conditions", 'diabetes')
WHERE NOT ('diabetes' = ANY ("conditions"))
  AND ("diagnosis" ILIKE '%당뇨%' OR "insulin_type" IS NOT NULL OR "insulin_unit_iu" IS NOT NULL);

-- ─── 중복 투여 차단 ──────────────────────────────────────────────────────────
-- 같은 펫에 3시간 안에 이미 투여 완료 기록이 있으면 저장을 거부한다.
-- 사용자가 경고를 확인하고 "그래도 추가"를 고르면 dose_override = true로 저장한다.
ALTER TABLE "public"."records"
  ADD COLUMN IF NOT EXISTS "dose_override" boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION "public"."guard_duplicate_dose"() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
    AS $$
DECLARE
  existing record;
BEGIN
  IF NEW.injection_status IS DISTINCT FROM 'given'
     OR coalesce(NEW.insulin_dose, 0) <= 0
     OR NEW.dose_override THEN
    RETURN NEW;
  END IF;

  -- 두 사람이 동시에 저장해도 한 건만 통과하도록 펫 단위로 직렬화
  PERFORM pg_advisory_xact_lock(hashtext('dose:' || NEW.pet_id::text));

  SELECT r.recorded_at, r.insulin_dose, nullif(u.full_name, '') AS writer
    INTO existing
  FROM public.records r
  LEFT JOIN public.users u ON u.id = r.writer_id
  WHERE r.pet_id = NEW.pet_id
    AND r.injection_status = 'given'
    AND coalesce(r.insulin_dose, 0) > 0
    AND r.recorded_at BETWEEN NEW.recorded_at - interval '3 hours' AND NEW.recorded_at + interval '3 hours'
    AND (TG_OP = 'INSERT' OR r.id <> NEW.id)
  ORDER BY abs(extract(epoch FROM r.recorded_at - NEW.recorded_at))
  LIMIT 1;

  IF FOUND THEN
    RAISE EXCEPTION 'DUPLICATE_DOSE'
      USING ERRCODE = 'P0001',
            DETAIL = json_build_object(
              'writer', existing.writer,
              'recorded_at', existing.recorded_at,
              'insulin_dose', existing.insulin_dose
            )::text,
            HINT = '같은 회차에 이미 투여 기록이 있습니다. 확인 후 dose_override로 저장하세요.';
  END IF;

  RETURN NEW;
END;
$$;

-- 트리거 연결은 20261001000500_enable_dose_guard.sql에서 한다.
-- v1.0 앱은 dose_override를 보낼 수 없어서, v1.1이 충분히 보급된 뒤에 운영에 반영한다.
