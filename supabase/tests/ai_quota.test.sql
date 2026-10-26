-- AI 코치 동의·한도 테스트: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000c1', 'free@test.local'),
  ('00000000-0000-0000-0000-0000000000c2', 'pro@test.local');
insert into public.families (id, created_by, pro_until) values
  ('f0000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-0000000000c1', null),
  ('f0000000-0000-0000-0000-0000000000c2', '00000000-0000-0000-0000-0000000000c2', now() + interval '30 days');
insert into public.user_families (user_id, family_id, role) values
  ('00000000-0000-0000-0000-0000000000c1', 'f0000000-0000-0000-0000-0000000000c1', 'owner'),
  ('00000000-0000-0000-0000-0000000000c2', 'f0000000-0000-0000-0000-0000000000c2', 'owner');
update public.app_config set value = '3' where key = 'ai_daily_limit_free';

-- ─── 서버 함수(service_role) 경로 ───────────────────────────────────────────
select is((select allowed from public.consume_ai_quota('00000000-0000-0000-0000-0000000000c1', 540)), true, '무료 1회차 허용');
select public.consume_ai_quota('00000000-0000-0000-0000-0000000000c1', 540);
select is((select used from public.consume_ai_quota('00000000-0000-0000-0000-0000000000c1', 540)), 3, '무료 3회차 허용 (한도 3)');
select is((select allowed from public.consume_ai_quota('00000000-0000-0000-0000-0000000000c1', 540)), false, '무료 4회차는 거부');
select is((select count from public.ai_usage where user_id = '00000000-0000-0000-0000-0000000000c1'), 3, '거부된 요청은 사용량을 늘리지 않는다');

select public.refund_ai_quota('00000000-0000-0000-0000-0000000000c1', 540);
select is((select allowed from public.consume_ai_quota('00000000-0000-0000-0000-0000000000c1', 540)), true, '실패 환불 후 다시 1회 허용');

select is((select daily_limit from public.consume_ai_quota('00000000-0000-0000-0000-0000000000c2', 540)), 100, '가족이 Pro면 Pro 한도');

select lives_ok(
  $$set local role service_role; insert into public.ai_usage_log (user_id, model, fake) values ('00000000-0000-0000-0000-0000000000c1', 'fake', true)$$,
  '서버 키는 호출 로그를 남길 수 있다'
);
reset role;

-- ─── 앱(authenticated) 경로 ────────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000c1","role":"authenticated"}';

select is((select consented from public.ai_quota_status(540)), false, '동의 전에는 consented = false');
select isnt(public.set_ai_consent(true), null, '본인 동의를 기록한다');
select results_eq(
  'select used, daily_limit, consented from public.ai_quota_status(540)',
  $$values (3, 3, true)$$,
  '앱은 오늘 사용량·한도·동의 여부를 본다'
);
select throws_ok(
  $$select public.consume_ai_quota('00000000-0000-0000-0000-0000000000c1', 540)$$,
  '42501', null,
  '앱은 한도 차감 함수를 직접 호출할 수 없다'
);
select throws_ok('select count(*) from public.ai_usage_log', '42501', null, '앱은 호출 로그를 읽을 수 없다');

reset role;
set local role anon;
select is((select (value #>> '{}') from public.app_config where key = 'min_supported_version'), '1.0.0', '로그인 전에도 최소 지원 버전을 읽을 수 있다');

select * from finish();
rollback;
