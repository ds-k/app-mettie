-- 가족 단위 접근 제어(RLS) 테스트: supabase test db
-- 사용자: owner(A, 피해 가족), partner(C, A의 가족), 외부 사용자(B), 초대받을 사용자(D)
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'owner@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'outsider@test.local'),
  ('00000000-0000-0000-0000-00000000000c', 'partner@test.local'),
  ('00000000-0000-0000-0000-00000000000d', 'invitee@test.local');

insert into public.families (id, created_by) values
  ('f0000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a');
insert into public.user_families (user_id, family_id, role) values
  ('00000000-0000-0000-0000-00000000000a', 'f0000000-0000-0000-0000-00000000000a', 'owner'),
  ('00000000-0000-0000-0000-00000000000c', 'f0000000-0000-0000-0000-00000000000a', 'partner');
insert into public.pets (id, family_id, name, species) values
  ('e0000000-0000-0000-0000-00000000000a', 'f0000000-0000-0000-0000-00000000000a', 'Coco', 'cat');
insert into public.invitations (code, family_id, created_by, expires_at) values
  ('ABC123', 'f0000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', now() + interval '1 day');

-- ─── 외부 사용자(B)의 공격 경로 ───────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}';

select is(
  (select count(*) from public.invitations), 0::bigint,
  '외부 사용자는 다른 가족의 초대 코드를 조회할 수 없다'
);

select throws_ok(
  $$insert into public.user_families (user_id, family_id)
    values ('00000000-0000-0000-0000-00000000000b', 'f0000000-0000-0000-0000-00000000000a')$$,
  '42501', null,
  '외부 사용자는 남의 가족에 직접 가입할 수 없다'
);

select is(
  (select count(*) from public.pets), 0::bigint,
  '외부 사용자는 다른 가족의 펫을 볼 수 없다'
);

-- 정상 흐름: 첫 펫 등록 시 내 가족을 만들고 owner로 연결
select lives_ok(
  $$insert into public.families (id) values ('f0000000-0000-0000-0000-00000000000b')$$,
  '사용자는 자기 가족을 만들 수 있다'
);
select lives_ok(
  $$insert into public.user_families (user_id, family_id, role)
    values ('00000000-0000-0000-0000-00000000000b', 'f0000000-0000-0000-0000-00000000000b', 'owner')$$,
  '사용자는 자기가 만든 가족에 owner로 연결할 수 있다'
);

-- ─── partner(C)의 권한 상승 ───────────────────────────────────────────────────
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}';

-- 권한 부족(42501)으로 막히든 정책에 걸려 0행이 바뀌든, 결과적으로 role이 바뀌지 않아야 한다
do $$
begin
  update public.user_families set role = 'owner'
    where user_id = '00000000-0000-0000-0000-00000000000c';
exception when insufficient_privilege then null;
end
$$;

reset role;
select is(
  (select role from public.user_families where user_id = '00000000-0000-0000-0000-00000000000c'),
  'partner',
  'partner는 자기 role을 owner로 바꿀 수 없다'
);

-- ─── 초대 코드로 참여(D) ─────────────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}';

select lives_ok(
  $$select public.join_family_with_code('ABC123')$$,
  '초대 코드로 가족에 참여할 수 있다'
);
select is(
  (select count(*) from public.pets), 1::bigint,
  '참여한 가족의 펫을 볼 수 있다'
);

-- ─── owner(A)는 자기 가족 초대 코드를 볼 수 있다 ─────────────────────────────
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';

select is(
  (select count(*) from public.invitations), 1::bigint,
  '가족 구성원은 자기 가족의 초대 코드를 볼 수 있다'
);

select * from finish();
rollback;
