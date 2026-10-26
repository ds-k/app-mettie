-- 가족 간 중복 투여 차단 트리거 연결
--
-- 운영 반영 시점: v1.1 앱이 충분히 보급된 뒤(필요하면 app_config.min_supported_version을 올려 강제 업데이트 후).
-- v1.0 앱은 dose_override와 DUPLICATE_DOSE를 처리하지 못해, 먼저 켜면 3시간 안 두 번째 투여 저장이 원문 에러로 실패한다.
DROP TRIGGER IF EXISTS "guard_duplicate_dose" ON "public"."records";
CREATE TRIGGER "guard_duplicate_dose"
  BEFORE INSERT OR UPDATE OF "injection_status", "insulin_dose", "recorded_at", "dose_override"
  ON "public"."records"
  FOR EACH ROW EXECUTE FUNCTION "public"."guard_duplicate_dose"();
