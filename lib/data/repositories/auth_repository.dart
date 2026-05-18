import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// AuthRepository 인스턴스 제공
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// 실시간 인증 상태 제공
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

// 현재 로그인한 사용자 제공
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user;
});

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithGoogle() async {
    // Phase 1: Native OAuth sign in. Web fallback for now.
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.mettie.app://login-callback',
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.mettie.app://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
