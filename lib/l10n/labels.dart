import '../data/app_error.dart';
import '../domain/glucose.dart';
import '../utils/korean.dart';
import 'app_localizations.dart';

// 도메인 값(DB에 저장되는 코드)을 화면 언어로 바꾼다.
// DB에는 언어와 무관한 코드만 저장해서, 가족이 서로 다른 언어를 써도 같은 기록이 각자 언어로 보인다.

String glucoseStatusLabel(AppLocalizations l, GlucoseStatus s) => switch (s) {
  GlucoseStatus.hypo => l.glucoseHypo,
  GlucoseStatus.low => l.glucoseLow,
  GlucoseStatus.inRange => l.glucoseInRange,
  GlucoseStatus.high => l.glucoseHigh,
  GlucoseStatus.veryHigh => l.glucoseVeryHigh,
};

/// glucose_type: pre_meal, post_meal, fasting, nadir, spot
const kGlucoseTypes = ['pre_meal', 'post_meal', 'fasting', 'nadir', 'spot'];

String? glucoseTypeLabel(AppLocalizations l, String? type) => switch (type) {
  'pre_meal' => l.glucoseTypePreMeal,
  'post_meal' => l.glucoseTypePostMeal,
  'fasting' => l.glucoseTypeFasting,
  'nadir' => l.glucoseTypeNadir,
  'spot' => l.glucoseTypeSpot,
  _ => null,
};

String? foodTypeLabel(AppLocalizations l, String? type) => switch (type) {
  'wet' => l.foodWet,
  'dry' => l.foodDry,
  'raw' => l.foodRaw,
  'mixed' => l.foodMixed,
  _ => null,
};

String appetiteLabel(AppLocalizations l, String code) => switch (code) {
  'partial' => l.appetitePartial,
  'anorexic' => l.appetiteNone,
  _ => l.appetiteGood,
};

String injectionStatusLabel(AppLocalizations l, String code) => switch (code) {
  'partial' => l.injectionPartial,
  'skipped' => l.injectionSkipped,
  _ => l.injectionGiven,
};

/// 관찰 항목 코드. 공통 항목은 기존 칼럼에, 나머지는 symptom_tags에 코드로 저장한다.
const kCommonObservations = [
  'drink_more',
  'urinate_more',
  'poor_appetite',
  'vomit',
  'lethargy',
];
const kDogObservations = ['walk_more', 'walk_less', 'eye_cloudy'];
const kCatObservations = ['litter_large', 'hind_gait'];

String observationLabel(AppLocalizations l, String code) => switch (code) {
  'drink_more' => l.obsDrinkMore,
  'urinate_more' => l.obsUrinateMore,
  'poor_appetite' => l.appetitePoor,
  'vomit' => l.obsVomit,
  'lethargy' => l.obsLethargy,
  'walk_more' => l.obsWalkMore,
  'walk_less' => l.obsWalkLess,
  'eye_cloudy' => l.obsEyeCloudy,
  'litter_large' => l.obsLitterLarge,
  'hind_gait' => l.obsHindGait,
  // 코드가 아닌 값(직접 입력 등)은 그대로 보여 준다
  _ => code,
};

/// 기록 작성자. 이름은 가족 구성원 RPC에서 오고, 본인이면 "나/Me/自分"으로 보여 준다.
class WriterName {
  final bool isMe;
  final String? name;

  const WriterName({required this.isMe, this.name});

  String label(AppLocalizations l) =>
      isMe ? l.commonMe : (name ?? l.commonFamily);

  /// 문장 주어 형태: 내가 / 엄마가 · You / Mom · 自分が / 엄마が
  String subject(AppLocalizations l) {
    if (isMe) return l.writerSubjectMe;
    final n = name ?? l.commonFamily;
    return l.localeName == 'ko' ? subjectOf(n) : l.writerSubjectOther(n);
  }
}

/// 인슐린 표시 이름. DB에는 VeterinaryGuidelines.insulinTypes의 값(예: '란투스(Lantus)')이 저장된다.
/// 목록에 없는 값(직접 입력)은 그대로 보여 준다.
String insulinDisplayName(AppLocalizations l, String stored) =>
    switch (stored) {
      '캐닌슐린(Vetsulin)' => l.insulinCaninsulin,
      '란투스(Lantus)' => l.insulinLantus,
      '레베미어(Levemir)' => l.insulinLevemir,
      '프로징크(ProZinc)' => l.insulinProZinc,
      '휴물린N/노볼린N(NPH)' => l.insulinNph,
      '트레시바(Tresiba)' => l.insulinTresiba,
      '투제오(Toujeo)' => l.insulinToujeo,
      '기타' => l.insulinOther,
      _ => stored,
    };

/// 에러를 사용자 언어의 문구로 바꾼다. 알 수 없는 에러는 원문을 노출하지 않는다.
String errorMessage(AppLocalizations l, Object? error) {
  if (error is! AppException) return l.errUnknown;
  return switch (error.code) {
    AppErrorCode.googleTokenMissing => l.errGoogleToken,
    AppErrorCode.googleSignInFailed => l.errGoogleSignIn,
    AppErrorCode.appleTokenMissing => l.errAppleToken,
    AppErrorCode.appleSignInFailed => l.errAppleSignIn,
    AppErrorCode.notSignedIn => l.errNotSignedIn,
    AppErrorCode.deleteAccountFailed => l.errDeleteAccount,
    AppErrorCode.inviteCreateFailed => l.errInviteCreate,
    AppErrorCode.inviteInvalid => l.errInviteInvalid,
    AppErrorCode.inviteExpired => l.errInviteExpired,
    AppErrorCode.inviteAlreadyJoined => l.errInviteAlreadyJoined,
    AppErrorCode.joinFailed => l.errJoinFailed,
    AppErrorCode.recordNotFound => l.errRecordNotFound,
    AppErrorCode.saveFailed => l.errSaveFailed,
  };
}
