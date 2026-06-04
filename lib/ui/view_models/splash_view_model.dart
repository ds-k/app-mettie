import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/llm_repository.dart';
import '../../data/repositories/auth_repository.dart';

enum SplashStatus { initializing, downloadingModel, checkingAuth, complete }

class SplashState {
  final SplashStatus status;
  final int downloadProgress; // 0 ~ 100
  final bool isAuth;

  SplashState({
    this.status = SplashStatus.initializing,
    this.downloadProgress = 0,
    this.isAuth = false,
  });

  SplashState copyWith({
    SplashStatus? status,
    int? downloadProgress,
    bool? isAuth,
  }) {
    return SplashState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isAuth: isAuth ?? this.isAuth,
    );
  }
}

final splashViewModelProvider = NotifierProvider<SplashViewModel, SplashState>(() {
  return SplashViewModel();
});

class SplashViewModel extends Notifier<SplashState> {
  @override
  SplashState build() {
    return SplashState();
  }

  Future<void> initializeApp() async {
    // 1. 모델 다운로드 및 초기화
    state = state.copyWith(status: SplashStatus.downloadingModel);
    final llmRepo = ref.read(llmRepositoryProvider);
    
    await llmRepo.initialize(onProgress: (progress) {
      // 0.0 ~ 1.0 (또는 0 ~ 100) 형태인지 확인. flutter_gemma는 0 ~ 100의 int를 반환
      state = state.copyWith(downloadProgress: progress);
    });

    // 2. Auth 상태 확인
    state = state.copyWith(status: SplashStatus.checkingAuth);
    final authState = ref.read(authStateProvider);
    final isAuth = authState.value?.session != null;

    // 3. 완료
    state = state.copyWith(status: SplashStatus.complete, isAuth: isAuth);
  }
}
