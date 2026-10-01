-- 같은 가족 구성원의 표시 이름 (기록 작성자, 투여한 사람 표시용)
-- users 테이블은 본인 행만 읽을 수 있으므로, 호출자가 속한 가족의 구성원만 돌려주는 함수로 노출한다.
CREATE OR REPLACE FUNCTION "public"."family_members"("p_family_id" uuid)
RETURNS TABLE ("user_id" uuid, "display_name" text, "role" text)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
    AS $$
  SELECT uf.user_id, coalesce(nullif(u.full_name, ''), '가족'), uf.role
  FROM public.user_families uf
  JOIN public.users u ON u.id = uf.user_id
  WHERE uf.family_id = p_family_id
    AND EXISTS (
      SELECT 1 FROM public.user_families me
      WHERE me.family_id = p_family_id AND me.user_id = auth.uid()
    )
  ORDER BY uf.created_at;
$$;

REVOKE ALL ON FUNCTION "public"."family_members"(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION "public"."family_members"(uuid) TO authenticated;
