/// 저장소가 던지는 에러. 화면은 errorMessage()로 사용자 언어의 문구를 만든다.
enum AppErrorCode {
  googleTokenMissing,
  googleSignInFailed,
  appleTokenMissing,
  appleSignInFailed,
  notSignedIn,
  deleteAccountFailed,
  inviteCreateFailed,
  inviteInvalid,
  inviteExpired,
  inviteAlreadyJoined,
  joinFailed,
  recordNotFound,
  saveFailed,
}

class AppException implements Exception {
  final AppErrorCode code;

  /// 로그용 원인. 사용자에게 그대로 보여 주지 않는다.
  final Object? cause;

  const AppException(this.code, [this.cause]);

  @override
  String toString() => 'AppException($code${cause == null ? '' : ': $cause'})';
}
