-- 가족 구성원 이름 조회 테스트: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000b1', 'me@test.local', '{"full_name":"나"}'),
  ('00000000-0000-0000-0000-0000000000b2', 'mom@test.local', '{"full_name":"엄마"}'),
  ('00000000-0000-0000-0000-0000000000b3', 'stranger@test.local', '{"full_name":"남"}');
insert into public.families (id, created_by) values
  ('f0000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000000b1');
insert into public.user_families (user_id, family_id, role) values
  ('00000000-0000-0000-0000-0000000000b1', 'f0000000-0000-0000-0000-0000000000b1', 'owner'),
  ('00000000-0000-0000-0000-0000000000b2', 'f0000000-0000-0000-0000-0000000000b1', 'partner');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000b1","role":"authenticated"}';
select is(
  (select array_agg(display_name order by display_name) from public.family_members('f0000000-0000-0000-0000-0000000000b1')),
  array['나','엄마'],
  '가족 구성원은 서로의 표시 이름을 볼 수 있다'
);

reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000b3","role":"authenticated"}';
select is(
  (select count(*) from public.family_members('f0000000-0000-0000-0000-0000000000b1')),
  0::bigint,
  '가족이 아닌 사용자는 구성원을 볼 수 없다'
);

reset role;
set local role anon;
select throws_ok(
  $$select * from public.family_members('f0000000-0000-0000-0000-0000000000b1')$$,
  '42501', null,
  '로그인하지 않은 요청은 호출할 수 없다'
);

select * from finish();
rollback;
