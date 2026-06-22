import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

    // 1. 초기화 (버전 7.0.0 이상부터 싱글톤 기반 initialize 사용)
    await GoogleSignIn.instance.initialize(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    try {
      // 2. 인증 시도 (성공 시 null이 아닌 값 반환, 취소 시 예외 발생)
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 3. 토큰 추출 (버전 7.0.0 이상부터 동기 getter로 변경)
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        // 캐시된 구버전(서버클라이언트 ID 누락) 세션이 남아있어서 idToken을 못 가져올 수 있음
        // 찌꺼기 세션을 지우고 다음에 다시 시도할 수 있도록 강제 로그아웃
        await GoogleSignIn.instance.signOut();
        throw '구글 ID 토큰을 찾을 수 없습니다. 다시 시도해주세요.';
      }

      // 4. Supabase 연동
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      // 사용자가 직접 취소한 경우는 예외를 던지지 않고 조용히 종료합니다.
      if (e.toString().contains('Canceled') || e.toString().contains('canceled')) {
        return;
      }
      throw '구글 로그인에 실패했습니다. 다시 시도해주세요.';
    }
  }

  Future<void> signInWithApple() async {
    // 1. Supabase에서 Raw Nonce 생성 및 해싱 (Replay 공격 방지)
    if (Platform.isIOS) {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      try {
        // 2. Apple 인증창 호출
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final idToken = credential.identityToken;
        if (idToken == null) throw '애플 ID 토큰을 찾을 수 없습니다.';

        // 3. Supabase로 ID 토큰 전송하여 세션 생성
        await _client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );

        // 4. Supabase 프로필 업데이트 (Apple OAuth 시 이름 정보 동기화)
        if (credential.givenName != null || credential.familyName != null) {
          final nameParts = <String>[];
          if (credential.givenName != null) {
            nameParts.add(credential.givenName!);
          }
          if (credential.familyName != null) {
            nameParts.add(credential.familyName!);
          }
          final fullName = nameParts.join(' ');
          await _client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': fullName,
                'given_name': credential.givenName,
                'family_name': credential.familyName,
              },
            ),
          );
        }
      } on SignInWithAppleAuthorizationException catch (e) {
        if (e.code == AuthorizationErrorCode.canceled) {
          return; // 사용자가 취소한 경우 조용히 종료
        }
        throw '애플 로그인에 실패했습니다: ${e.message}';
      } catch (e) {
        throw '애플 로그인에 실패했습니다. 다시 시도해주세요.';
      }
    } else {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.mettie.app://login-callback',
      );
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmailPassword(
    String email,
    String password, {
    String? fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
      emailRedirectTo: 'com.mettie.app://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      // Supabase RPC를 통한 회원 탈퇴 시도
      await _client.rpc('delete_user');
      // 백엔드 탈퇴 성공 시에만 기기에서 로그아웃 처리
      await _client.auth.signOut();
    } catch (e) {
      // 에러 발생 시(RPC 없음, 네트워크 오류 등) 강제 로그아웃하지 않고 에러를 던짐
      throw '회원탈퇴에 실패했습니다. 데이터베이스 설정을 확인하거나 네트워크 연결을 확인해주세요.';
    }
  }
}
