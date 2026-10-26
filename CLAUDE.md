# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Mettie(메티) — 당뇨 반려동물(개/고양이)의 혈당·인슐린·사료·체중 기록을 가족 단위로 공유하고, Claude API(Supabase Edge Function 경유)로 코칭하는 Flutter 앱. 백엔드는 Supabase. 한국어·영어·일본어.

## 명령어

```bash
flutter pub get                        # 의존성 설치 (새 워크트리에서도 먼저 실행)
flutter analyze                        # 린트 (flutter_lints)
flutter run -d <device-id>             # 실행 (flutter devices로 ID 확인)
flutter build appbundle --release      # Play 스토어 배포용
flutter build ipa --release            # App Store 배포용
dart run flutter_launcher_icons        # 앱 아이콘 재생성 (pubspec 설정 기반)
dart run flutter_native_splash:create  # 스플래시 재생성
```

```bash
flutter test                                   # 전체 테스트
flutter test test/reload_regression_test.dart  # 단일 파일
```

provider 테스트는 `ProviderContainer`에 `authStateProvider`와 저장소 provider를 fake로 override해서 Supabase 없이 돌린다 (`test/reload_regression_test.dart` 참고).

## git에 없는 로컬 파일 (새 워크트리 세팅 시 복사 필요)

- `.env` — `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, `WEB_BASE_URL`. `pubspec.yaml`에 에셋으로 번들되며 `main.dart`에서 `flutter_dotenv`로 로드한다.
- `android/key.properties`, `android/app/upload-keystore.jks` — 릴리스 서명용. 없으면 release 빌드 서명 실패 (debug는 무관).

## Supabase (`supabase/`)

마이그레이션, RLS 테스트, Edge Function을 레포에서 관리한다. 운영 프로젝트 ref는 `mqbppfnbzkvkzjbdzhow`.

```bash
supabase start -x studio,imgproxy,vector,logflare,supavisor,mailpit,postgres-meta,storage-api,edge-runtime  # 로컬 dev DB (Docker)
supabase db reset          # 로컬에 마이그레이션 전부 재적용
supabase test db           # supabase/tests/*.sql (pgTAP) 실행
./supabase/dev/seed_demo.sh  # 로컬 DB에 데모 가족·펫·14일치 기록 (test@test.test / testtest)
```

- 스키마 변경은 `supabase/migrations/`에 파일로 추가하고 **로컬에서 `supabase test db` 통과 후** 운영에 반영한다.
- 이 개발 환경에서는 원격 DB 직접 연결(`db push`, `migration list --linked`, 링크된 상태의 `supabase start`)이 멈춘다. 운영 반영은 Management API를 쓰는 `supabase db query --linked -f <file>`로 하고, `supabase_migrations.schema_migrations`에 버전을 같이 기록한다. 로컬 기동이 멈추면 `supabase/.temp`(링크 정보)를 잠시 치우고 띄운다.
- **v1.1.0 운영 반영 순서**: 배포 직전에 `20261001000200`(관리 계획), `000300`(가족 이름), `000400`(AI 코치)을 반영하고 함수를 배포한다. `000500`(중복 투여 트리거)은 v1.0 앱이 중복 투여 거부를 처리하지 못하므로 v1.1 보급 후(필요하면 `min_supported_version`을 올린 뒤) 반영한다.
- 가족 참여는 `join_family_with_code` RPC로만 한다. `user_families` 직접 INSERT는 자기가 만든 가족에 owner로 연결할 때만 허용된다 (`supabase/tests/family_rls.test.sql`).

## 아키텍처

MVVM + Riverpod 3. 레이어 방향은 `ui/views → ui/view_models → data/repositories → Supabase`. 화면과 무관한 계산(혈당 상태 분류, 목표 범위 비율, 투여 회차·중복 판정, 타임라인 묶음)은 `lib/domain/`의 순수 함수로 두고 `test/domain_test.dart`로 고정한다.

- **상태 관리 규칙**: Riverpod 코드 생성(`@riverpod` annotation, build_runner)을 쓰지 않는다. `Provider` / `StreamProvider` / `NotifierProvider` + `Notifier`를 직접 선언한다. provider는 해당 클래스와 같은 파일 상단에 정의한다.
- **Repository**: `Supabase.instance.client`를 주입받는 얇은 래퍼. 에러는 한국어 사용자 메시지 문자열을 그대로 `throw`하는 패턴이다 (뷰에서 그대로 표시).
- **인증·라우팅**: go_router `redirect`에서 로그인 여부로 `/login` ↔ `/home/today`를 분기한다. 홈은 `StatefulShellRoute.indexedStack` 4탭(`/home/today` 홈 · `/home/trends` 추이 · `/home/ai-coach` · `/home/book` 건강수첩)과 가운데 기록 추가 버튼. 설정은 `/settings`(최상위 내비게이터). 바텀시트는 `useRootNavigator: true`로 열어야 하단 탭에 가리지 않는다. 소셜 로그인 딥링크는 `com.mettie.app://login-callback`.
- **리빌드 범위 주의**: `routerProvider`는 인증 상태를 `watch`하지 않고 `refreshListenable`로 redirect만 다시 평가한다. 인증·펫처럼 객체가 자주 새로 만들어지는 provider는 `.select((x) => x?.id)`로 ID만 구독하고, 화면의 로딩 분기는 `isLoading`이 아니라 `!hasValue`로 판단한다. 어기면 대시보드가 반복해서 리로드된다.
- **데이터 흐름**: `petsProvider` → `selectedPetIdProvider` → `currentPetProvider` → `recordsStreamProvider`(펫별 최근 500건 realtime `.stream()`, 최신순). 다른 펫 기록은 `petRecordsProvider(petId)`, 작성자 이름은 `writerNameProvider`(RPC `family_members`), 남은 시간 표시는 `clockProvider`. 공용 provider는 `ui/view_models/dashboard_view_model.dart`에 있다.
- **질환 모듈**: `pets.conditions`(현재 `diabetes`)에 따라 홈·건강수첩 카드가 달라진다. 당뇨가 아닌 펫도 공통 카드(오늘 기록, 체중)로 쓸 수 있어야 한다. 강아지·고양이 공용이므로 종별 기본값(목표 범위 강아지 100–250, 고양이 100–300)과 종별 관찰 항목을 유지한다.
- **중복 투여**: 같은 펫 3시간 안의 두 번째 투여 완료 기록은 서버 트리거 `guard_duplicate_dose`가 `DUPLICATE_DOSE`로 거부한다. 앱은 저장 전 `findConflictingDose`로 먼저 경고하고, 보호자가 확인하면 `dose_override = true`로 저장한다. 창(3시간)은 `lib/domain/dosing.dart`와 트리거에서 같아야 한다.
- **혼합 급여**: 사료는 종류별로 한 건씩 저장하고 타임라인(`buildTimeline`)에서 15분 안의 같은 작성자 사료를 한 끼로 묶는다.

### 멀티 테넌트 데이터 모델

펫은 사용자가 아니라 **family**에 속한다. `users ↔ user_families(role: owner/member) ↔ families → pets → records`. 사용자가 볼 수 있는 펫은 `pets`를 `families!inner(user_families!inner(...))`로 조인해 `user_id`로 필터링한다 (`PetRepository.getPets`). 가족 공유는 `invitations` 테이블의 6자리 코드(24시간 만료)로 한다. 스키마는 `supabase/migrations/`가 기준이다.

### AI 코치 (Claude API)

- 앱은 Anthropic을 직접 부르지 않는다. `AiCoachRepository`가 Edge Function `supabase/functions/ai-coach`를 `functions.invoke`로 호출하고 SSE(`meta`→`delta`…→`refs`→`done` 또는 `error`)를 받는다.
- 서버 함수 순서: 인증 → 동의(`users.ai_consent_at`) → 사용자 토큰으로 펫·14일 기록 조회(RLS) → `consume_ai_quota`로 하루 한도 차감(응답 전 실패 시 `refund_ai_quota`) → Claude 스트리밍 → `[[refs: R1]]`로 근거 기록 추출 → `ai_usage_log`에 토큰·캐시 사용량 기록.
- 모델은 무료·Pro 구분 없이 `claude-opus-5-5`, `effort: low`, `fallbacks: "default"`(beta `server-side-fallback-2026-07-01`). 더 싼 모델로 바꾸지 않는다(정확도 우선 결정). 비용은 `app_config`의 하루 한도(무료 10, Pro 100)로 통제한다. Pro는 사용자가 속한 가족 중 하나라도 `families.pro_until`이 미래면 적용된다.
- 프롬프트(`prompt.ts`): `STATIC_SYSTEM`은 펫·시각·언어를 섞지 않아야 캐시가 맞는다(Opus 5.5 최소 512토큰, 현재 약 1.1k). 펫 정보·기록·응답 언어는 두 번째 system 블록. 안전 규칙(용량 조정 지시 금지, 저혈당 응급 우선, U-40/U-100 경고)은 여기서 바꾼다.
- 시크릿: `ANTHROPIC_API_KEY`. 키 없이 개발할 때는 `AI_COACH_FAKE=1`(가짜 응답, 로그에 `fake=true`). 둘 다 없으면 503.
- 로컬 실행: 함수 런타임 대신 `deno run --allow-env --allow-net supabase/functions/ai-coach/index.ts`(포트 8000, `SUPABASE_URL`/`SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY` 필요). 테스트는 `deno test supabase/functions/ai-coach`.
- 앱 시작 시 `cleanupLegacyModelFiles()`가 v1.0 온디바이스 모델(약 2GB)과 다운로드 조각을 지운다. `app_config.min_supported_version`보다 낮은 앱은 스플래시에서 업데이트 화면으로 막는다.

## 다국어 (한국어·영어·일본어)

- 화면 문자열은 전부 `lib/l10n/app_ko.arb`(템플릿)·`app_en.arb`·`app_ja.arb`에 넣고 `context.l10n.키`로 쓴다(`lib/l10n/l10n.dart`). 코드에 화면 문자열을 직접 쓰지 않는다. ARB를 고치면 `flutter gen-l10n`(또는 `flutter pub get`)으로 `app_localizations*.dart`를 다시 만든다.
- 세 파일의 키·자리 표시자가 다르면 `test/l10n_test.dart`가 실패한다. 기기 언어가 셋 중 하나가 아니면 영어로 보인다.
- 문장 안에 값이 들어가면 문자열을 이어 붙이지 말고 ARB 자리 표시자(`{name}`)를 쓴다. 언어마다 어순이 다르다. 링크가 섞인 문장은 자리 표시자에 구분 문자를 넣어 나눈다(`email_login_view.dart`의 `_agreeParts`).
- DB에는 언어와 무관한 코드만 저장한다(관찰 항목 `symptom_tags`, `glucose_type` 등). 표시 이름은 `lib/l10n/labels.dart`에서 바꾼다. 인슐린은 기존 저장값(`란투스(Lantus)`)을 유지하고 `insulinDisplayName`으로만 현지화한다.
- 작성자 이름은 `WriterName`(`label`/`subject`)으로 쓴다. 한국어 주격 조사(내가/엄마가)는 `subject`가 처리한다.
- 저장소는 화면 문구를 `throw`하지 않는다. `AppException(AppErrorCode.xxx)`를 던지고 화면은 `errorMessage(l10n, error)`로 보여 준다.
- 날짜는 `DateFormat.MMMEd(l10n.localeName)`처럼 언어를 넘겨 만든다. 혈당 단위는 아직 mg/dL만 지원한다(mmol/L은 표시 단계 변환으로 추가 예정).
- 앱 이름: iOS `ios/Runner/{ko,en,ja}.lproj/InfoPlist.strings`(권한 문구 포함), Android `res/values{,-ko,-ja}/strings.xml`.
- AI 답변 언어는 앱이 보낸 `locale`로 서버 프롬프트가 지정한다.

## UI 규칙

- 아이콘은 `lucide_icons_flutter`(`LucideIcons.*`)만 쓴다. Material `Icons.*`는 쓰지 않는다.
- 폰트는 로컬 에셋 Pretendard(400/500/600/700). 색상과 타이포는 `lib/core/constants/app_colors.dart`, `app_typography.dart`, 테마는 `lib/core/theme/app_theme.dart`.
- 코드 주석은 한국어로 쓴다. UI 문자열은 ARB에 둔다.

## 플랫폼별 주의사항

- **Android 16KB 페이지 크기**: Play는 모든 `.so`가 16KB 정렬이어야 받아준다. 네이티브 의존성을 추가하거나 올릴 때는 README의 `llvm-readelf` 검증 스크립트로 AAB를 확인한다 (v1.0의 flutter_gemma 사례).
- **release 빌드는 ProGuard 규칙**(`android/app/proguard-rules.pro`)이 적용된다. 네이티브·리플렉션 기반 플러그인을 추가하면 keep 규칙이 필요한지 확인한다.
- **iOS는 CocoaPods 없이 Swift Package Manager만 쓴다.** `Podfile`이 없는 게 정상이다. SPM을 지원하지 않는 플러그인을 추가하면 Flutter가 기본 `Podfile`을 다시 만드는데, 그때는 `post_install`에서 모든 pod의 `IPHONEOS_DEPLOYMENT_TARGET`을 16.0으로 맞춰야 한다 (Xcode 27은 15.0 미만 타깃을 빌드하지 못함).
- **Xcode 27 + Flutter 3.47.5 이상이 필요하다.** 3.44 이하는 Xcode 27의 `lipo -verify_arch` 변경 때문에 시뮬레이터 유니버설 빌드가 실패한다.
