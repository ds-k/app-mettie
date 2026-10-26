import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

// Riverpod 3.0 스펙 준수 (Generator/Annotation 절대 사용 금지)
final loginViewModelProvider =
    NotifierProvider<LoginViewModel, AsyncValue<void>>(
      () => LoginViewModel(),
      isAutoDispose: true,
    );

class LoginViewModel extends Notifier<AsyncValue<void>> {
  late final AuthRepository _authRepository;

  @override
  AsyncValue<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {String? fullName}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUpWithEmailPassword(
        email,
        password,
        fullName: fullName,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}
