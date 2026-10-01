-- 가족 간 중복 투여 차단 테스트: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000a1', 'me@test.local', '{"full_name":"나"}'),
  ('00000000-0000-0000-0000-0000000000a2', 'mom@test.local', '{"full_name":"엄마"}');
insert into public.families (id, created_by) values
  ('f0000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1');
insert into public.user_families (user_id, family_id, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'f0000000-0000-0000-0000-0000000000a1', 'owner'),
  ('00000000-0000-0000-0000-0000000000a2', 'f0000000-0000-0000-0000-0000000000a1', 'partner');
insert into public.pets (id, family_id, name, species, diagnosis) values
  ('e0000000-0000-0000-0000-0000000000a1', 'f0000000-0000-0000-0000-0000000000a1', 'Coco', 'cat', '당뇨'),
  ('e0000000-0000-0000-0000-0000000000a2', 'f0000000-0000-0000-0000-0000000000a1', 'Bori', 'dog', null);

-- 엄마가 19:00에 투여
insert into public.records (pet_id, writer_id, recorded_at, insulin_dose, injection_status) values
  ('e0000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2', '2026-10-01 19:00+09', 2, 'given');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}';

select throws_ok(
  $$insert into public.records (pet_id, writer_id, recorded_at, insulin_dose, injection_status)
    values ('e0000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1', '2026-10-01 19:20+09', 2, 'given')$$,
  'P0001', 'DUPLICATE_DOSE',
  '같은 회차(3시간 안)의 두 번째 투여는 거부된다'
);

select lives_ok(
  $$insert into public.records (pet_id, writer_id, recorded_at, insulin_dose, injection_status, dose_override)
    values ('e0000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1', '2026-10-01 19:25+09', 2, 'given', true)$$,
  '경고를 확인하고 dose_override로 저장하면 통과한다'
);

select lives_ok(
  $$insert into public.records (pet_id, writer_id, recorded_at, insulin_dose, injection_status)
    values ('e0000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1', '2026-10-02 07:00+09', 2, 'given')$$,
  '다음 회차(12시간 뒤) 투여는 통과한다'
);

select lives_ok(
  $$insert into public.records (pet_id, writer_id, recorded_at, insulin_dose, injection_status)
    values ('e0000000-0000-0000-0000-0000000000a2', '00000000-0000-0000-0000-0000000000a1', '2026-10-01 19:10+09', 5, 'given')$$,
  '다른 펫의 투여는 영향을 받지 않는다'
);

select lives_ok(
  $$insert into public.records (pet_id, writer_id, recorded_at, insulin_dose, injection_status)
    values ('e0000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1', '2026-10-01 19:30+09', 0, 'skipped')$$,
  '생략 기록은 막지 않는다'
);

select lives_ok(
  $$insert into public.records (pet_id, writer_id, recorded_at, glucose_value)
    values ('e0000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1', '2026-10-01 19:40+09', 210)$$,
  '혈당만 있는 기록은 막지 않는다'
);

reset role;
select is(
  (select conditions from public.pets where id = 'e0000000-0000-0000-0000-0000000000a1'),
  '{}'::text[],
  '마이그레이션 이후 새로 만든 펫의 질환 모듈은 비어 있다 (앱이 등록 시 지정)'
);

select * from finish();
rollback;
