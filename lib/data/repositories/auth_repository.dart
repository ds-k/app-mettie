import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_error.dart';

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
        throw const AppException(AppErrorCode.googleTokenMissing);
      }

      // 4. Supabase 연동
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      // 사용자가 직접 취소한 경우는 예외를 던지지 않고 조용히 종료합니다.
      if (e.toString().contains('Canceled') ||
          e.toString().contains('canceled')) {
        return;
      }
      throw AppException(AppErrorCode.googleSignInFailed, e);
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
        if (idToken == null) {
          throw const AppException(AppErrorCode.appleTokenMissing);
        }

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
        throw AppException(AppErrorCode.appleSignInFailed, e.message);
      } on AppException {
        rethrow;
      } catch (e) {
        throw AppException(AppErrorCode.appleSignInFailed, e);
      }
    } else {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.mettie.app://login-callback',
      );
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
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
      emailRedirectTo: 'https://mettieapp.com/email-verified',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AppException(AppErrorCode.notSignedIn);

      // 유저가 Apple로 로그인했는지 확인
      // user.appMetadata['providers'] 안에 'apple'이 포함되어 있는지 체크
      final List<dynamic>? providers = user.appMetadata['providers'];
      final bool isAppleUser = providers != null && providers.contains('apple');

      if (isAppleUser) {
        // Apple 로그인 유저라면, 탈퇴(Revoke)를 위해 Authorization Code를 한 번 더 발급받습니다.
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final authCode = credential.authorizationCode;

        // 발급받은 Authorization Code를 Edge Function으로 보내서 Revoke 및 계정 삭제 처리를 위임
        await _client.functions.invoke(
          'revoke-apple-token',
          body: {'authorization_code': authCode},
        );
      } else {
        // Apple 로그인이 아닌 경우 (구글, 이메일 등) 기존 RPC로 계정 삭제
        await _client.rpc('delete_user');
      }

      // 백엔드 탈퇴(또는 Edge Function 처리) 완료 시 기기에서 로그아웃 처리
      await _client.auth.signOut();
    } catch (e) {
      // 에러 발생 시 강제 로그아웃하지 않고 에러를 던짐
      throw AppException(AppErrorCode.deleteAccountFailed, e);
    }
  }
}
