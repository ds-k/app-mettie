import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/llm_repository.dart';
import '../../data/repositories/auth_repository.dart';

enum SplashStatus { initializing, checkingAuth, complete }

class SplashState {
  final SplashStatus status;
  final bool isAuth;

  SplashState({this.status = SplashStatus.initializing, this.isAuth = false});

  SplashState copyWith({SplashStatus? status, bool? isAuth}) {
    return SplashState(
      status: status ?? this.status,
      isAuth: isAuth ?? this.isAuth,
    );
  }
}

final splashViewModelProvider = NotifierProvider<SplashViewModel, SplashState>(
  () {
    return SplashViewModel();
  },
);

class SplashViewModel extends Notifier<SplashState> {
  @override
  SplashState build() {
    return SplashState();
  }

  Future<void> initializeApp() async {
    // 1. LLM 초기화 (다운로드 없이 Core만 가볍게 초기화)
    final llmRepo = ref.read(llmRepositoryProvider);
    await llmRepo.initialize();

    // 2. Auth 상태 확인
    state = state.copyWith(status: SplashStatus.checkingAuth);
    final authState = ref.read(authStateProvider);
    final isAuth = authState.value?.session != null;

    // 3. 완료
    state = state.copyWith(status: SplashStatus.complete, isAuth: isAuth);
  }
}
