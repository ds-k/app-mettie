# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Mettie(메티) — 당뇨 반려동물(개/고양이)의 혈당·인슐린·사료·체중 기록을 가족 단위로 공유하고, 온디바이스 LLM(Gemma 4)으로 코칭하는 Flutter 앱. 백엔드는 Supabase.

## 명령어

```bash
flutter pub get                        # 의존성 설치 (새 워크트리에서도 먼저 실행)
cd ios && pod install && cd ..         # iOS 네이티브 의존성
flutter analyze                        # 린트 (flutter_lints)
flutter run -d <device-id>             # 실행 (flutter devices로 ID 확인)
flutter build appbundle --release      # Play 스토어 배포용
flutter build ipa --release            # App Store 배포용
dart run flutter_launcher_icons        # 앱 아이콘 재생성 (pubspec 설정 기반)
dart run flutter_native_splash:create  # 스플래시 재생성
```

`test/` 디렉터리는 아직 없다. 테스트를 추가하면 `flutter test test/<file>_test.dart`로 단일 파일을 실행한다.

## git에 없는 로컬 파일 (새 워크트리 세팅 시 복사 필요)

- `.env` — `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, `WEB_BASE_URL`. `pubspec.yaml`에 에셋으로 번들되며 `main.dart`에서 `flutter_dotenv`로 로드한다.
- `android/key.properties`, `android/app/upload-keystore.jks` — 릴리스 서명용. 없으면 release 빌드 서명 실패 (debug는 무관).

## 아키텍처

MVVM + Riverpod 3. 레이어 방향은 `ui/views → ui/view_models → data/repositories → Supabase / flutter_gemma`.

- **상태 관리 규칙**: Riverpod 코드 생성(`@riverpod` annotation, build_runner)을 쓰지 않는다. `Provider` / `StreamProvider` / `NotifierProvider` + `Notifier`를 직접 선언한다. provider는 해당 클래스와 같은 파일 상단에 정의한다.
- **Repository**: `Supabase.instance.client`를 주입받는 얇은 래퍼. 에러는 한국어 사용자 메시지 문자열을 그대로 `throw`하는 패턴이다 (뷰에서 그대로 표시).
- **인증·라우팅**: `authStateProvider`(Supabase `onAuthStateChange` 스트림)를 `routerProvider`가 watch하고, go_router `redirect`에서 로그인 여부로 `/login` ↔ `/home/dashboard`를 분기한다. 홈은 `StatefulShellRoute.indexedStack` 4탭(dashboard / ai-coach / pet-management / profile). 소셜 로그인 딥링크는 `com.mettie.app://login-callback`.
- **데이터 흐름**: `petsProvider`(pet_management_view_model) → `selectedPetIdProvider` → `currentPetProvider` → `recordsStreamProvider`(Supabase realtime `.stream()`) → `DashboardViewModel`이 `ref.listen`으로 요약 통계 계산. 여러 뷰모델이 `currentPetProvider`를 공유한다.

### 멀티 테넌트 데이터 모델

펫은 사용자가 아니라 **family**에 속한다. `users ↔ user_families(role: owner/member) ↔ families → pets → records`. 사용자가 볼 수 있는 펫은 `pets`를 `families!inner(user_families!inner(...))`로 조인해 `user_id`로 필터링한다 (`PetRepository.getPets`). 가족 공유는 `invitations` 테이블의 6자리 코드(24시간 만료)로 한다. DB 스키마 SQL은 레포에 없다. README의 ER 다이어그램을 참고한다.

### 온디바이스 AI 코치

- `LlmRepository`(`lib/data/repositories/llm_repository.dart`): 앱 기동 시 스플래시에서 `FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()])`만 호출하고, 모델(`gemma-4-E2B-it.litertlm`, HuggingFace에서 다운로드)은 AI 코치 탭에서 사용자가 명시적으로 받는다.
- 메모리 한계 때문에 **매 턴마다 채팅 세션을 새로 만들고** 최근 4개 메시지만 다시 주입한다. `maxTokens: 2048`.
- `RagContextInjector`(`lib/utils/rag_context_injector.dart`)는 벡터 검색이 아니라, 펫 정보 + 최근 기록 + `VeterinaryGuidelines`(인슐린 사전·수의학 가이드라인)를 문자열로 직렬화해 시스템 프롬프트에 넣는 방식이다. 응답 250자 제한 같은 프롬프트 규칙도 여기 있다.
- `flutter_gemma` 1.x는 모듈이 분리돼 있어 `flutter_gemma_litertlm`을 함께 쓴다. RAG(qdrant) 패키지는 의도적으로 추가하지 않는다 (아래 16KB 이슈).

## UI 규칙

- 아이콘은 `lucide_icons_flutter`(`LucideIcons.*`)만 쓴다. Material `Icons.*`는 쓰지 않는다.
- 폰트는 로컬 에셋 Pretendard(400/500/600/700). 색상과 타이포는 `lib/core/constants/app_colors.dart`, `app_typography.dart`, 테마는 `lib/core/theme/app_theme.dart`.
- UI 문자열과 코드 주석은 한국어로 쓴다.

## 플랫폼별 주의사항

- **Android 16KB 페이지 크기**: Play는 모든 `.so`가 16KB 정렬이어야 받아준다. `android/app/build.gradle.kts`의 `packaging.jniLibs.excludes`에서 Qualcomm QNN `libQnnHtpV*Skel.so`를 제외하고 있으니 지우지 않는다. 네이티브 의존성을 추가하거나 올릴 때는 README의 `llvm-readelf` 검증 스크립트로 AAB를 확인한다.
- **release 빌드는 ProGuard 규칙**(`android/app/proguard-rules.pro`)이 적용된다. 네이티브·리플렉션 기반 플러그인을 추가하면 keep 규칙이 필요한지 확인한다.
- **iOS는 Swift Package Manager가 켜져 있다.** SPM을 지원하는 플러그인(예: `flutter_gemma`)은 CocoaPods가 아니라 SPM으로 들어오므로 `Podfile.lock`에 없는 게 정상이다.
