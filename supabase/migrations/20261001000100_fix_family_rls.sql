-- 가족(family) 접근 제어 RLS 보강
--
-- 기존 정책의 문제:
-- 1. invitations SELECT가 USING (true)라 로그인한 누구나 모든 가족의 초대 코드와 family_id를 조회할 수 있었다.
-- 2. user_families INSERT가 user_id만 검사해서, 알아낸 family_id로 남의 가족에 직접 가입할 수 있었다.
--    role 기본값이 'owner'라 owner로 가입되고, 나가는 순간 handle_user_family_deletion 트리거가 그 가족 전체를 삭제한다.
-- 3. user_families UPDATE로 partner가 자기 role을 owner로 바꿀 수 있었다.
--
-- 가족 참여는 초대 코드를 검증하는 join_family_with_code(SECURITY DEFINER) RPC로만 하도록 한다.

-- 1. 초대 코드는 같은 가족 구성원만 조회
DROP POLICY IF EXISTS "Enable select for authenticated users" ON "public"."invitations";
DROP POLICY IF EXISTS "Anyone can read valid invitations" ON "public"."invitations";

CREATE POLICY "Members can read their family invitations" ON "public"."invitations"
  FOR SELECT TO "authenticated"
  USING ("family_id" IN (
    SELECT "user_families"."family_id" FROM "public"."user_families"
    WHERE "user_families"."user_id" = "auth"."uid"()
  ));

-- 2. 직접 INSERT는 내가 방금 만든 가족에 owner로 연결하는 경우만 허용 (펫 최초 등록 흐름)
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON "public"."user_families";

CREATE POLICY "Creators can link themselves to their own family" ON "public"."user_families"
  FOR INSERT TO "authenticated"
  WITH CHECK (
    "user_id" = "auth"."uid"()
    AND "role" = 'owner'
    AND "family_id" IN (
      SELECT "families"."id" FROM "public"."families"
      WHERE "families"."created_by" = "auth"."uid"()
    )
  );

-- 3. role 변경 경로 제거 (앱에서 UPDATE를 쓰지 않는다)
DROP POLICY IF EXISTS "Enable update for users in family" ON "public"."user_families";
