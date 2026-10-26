// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '메티';

  @override
  String get commonSave => '저장';

  @override
  String commonSaveCount(int count) {
    return '$count건 저장';
  }

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonEdit => '수정';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonSettings => '설정';

  @override
  String get commonUnset => '미설정';

  @override
  String get commonAdd => '추가';

  @override
  String get commonMe => '나';

  @override
  String get commonFamily => '가족';

  @override
  String get commonNetworkError => '저장하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.';

  @override
  String get commonLoadError => '데이터를 불러오지 못했습니다.';

  @override
  String get navHome => '홈';

  @override
  String get navTrends => '추이';

  @override
  String get navCoach => 'AI 코치';

  @override
  String get navBook => '건강수첩';

  @override
  String get navAddRecord => '기록 추가';

  @override
  String get needPetFirstForRecord => '기록을 추가하려면 먼저 반려동물을 등록해주세요.';

  @override
  String get switchPet => '반려동물 바꾸기';

  @override
  String get unitMgdl => 'mg/dL';

  @override
  String get unitIu => 'IU';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get speciesDog => '강아지';

  @override
  String get speciesCat => '고양이';

  @override
  String get glucoseHypo => '저혈당';

  @override
  String get glucoseLow => '낮음';

  @override
  String get glucoseInRange => '목표 범위';

  @override
  String get glucoseHigh => '높음';

  @override
  String get glucoseVeryHigh => '매우 높음';

  @override
  String get glucoseTypePreMeal => '식전';

  @override
  String get glucoseTypePostMeal => '식후';

  @override
  String get glucoseTypeFasting => '공복';

  @override
  String get glucoseTypeNadir => 'nadir';

  @override
  String get glucoseTypeSpot => '임의';

  @override
  String get foodWet => '습식';

  @override
  String get foodDry => '건식';

  @override
  String get foodRaw => '생식';

  @override
  String get foodMixed => '혼합';

  @override
  String get foodGeneric => '사료';

  @override
  String get appetiteGood => '잘 먹음';

  @override
  String get appetitePartial => '조금 남김';

  @override
  String get appetiteNone => '안 먹음';

  @override
  String get appetitePoor => '식욕 저하';

  @override
  String get injectionGiven => '투여 완료';

  @override
  String get injectionPartial => '일부 투여';

  @override
  String get injectionSkipped => '생략';

  @override
  String get obsDrinkMore => '물 많이 마심';

  @override
  String get obsDrinkLess => '물 적게 마심';

  @override
  String get obsUrinateMore => '소변 많음';

  @override
  String get obsUrinateLess => '소변 적음';

  @override
  String get obsNoAppetite => '식욕 없음';

  @override
  String get obsVomit => '구토';

  @override
  String obsVomitCount(int count) {
    return '구토 $count회';
  }

  @override
  String get obsDiarrhea => '설사';

  @override
  String get obsConstipation => '변비';

  @override
  String get obsLethargy => '무기력';

  @override
  String get obsWalkMore => '산책 평소보다 많음';

  @override
  String get obsWalkLess => '산책 평소보다 적음';

  @override
  String get obsEyeCloudy => '눈 혼탁·시야 이상';

  @override
  String get obsLitterLarge => '화장실 덩어리 큼';

  @override
  String get obsHindGait => '뒷다리 걸음 이상';

  @override
  String get writerSubjectMe => '내가';

  @override
  String writerSubjectOther(String name) {
    return '$name';
  }

  @override
  String tlInsulin(String dose) {
    return '인슐린 $dose IU';
  }

  @override
  String tlInsulinPartial(String dose) {
    return '인슐린 일부 $dose IU';
  }

  @override
  String get tlInsulinSkipped => '인슐린 생략';

  @override
  String tlGlucose(int value) {
    return '혈당 $value';
  }

  @override
  String tlFoodAmount(String grams) {
    return '사료 $grams g';
  }

  @override
  String tlWeight(String kg) {
    return '체중 $kg kg';
  }

  @override
  String get tlEmptyFiltered => '이 조건의 기록이 없습니다.';

  @override
  String get tlToday => '오늘';

  @override
  String tlHypoCount(int count) {
    return '저혈당 $count회';
  }

  @override
  String tlDoses(int given, int planned) {
    return '투여 $given/$planned';
  }

  @override
  String tlSkippedCount(int count) {
    return '생략 $count';
  }

  @override
  String tlGlucoseSingle(int value) {
    return '혈당 $value';
  }

  @override
  String tlGlucoseAverage(int value) {
    return '혈당 평균 $value';
  }

  @override
  String todayDiagnosisDay(int days) {
    return '진단 $days일째';
  }

  @override
  String get remainingSoon => '곧';

  @override
  String remainingMinutes(int m) {
    return '$m분 후';
  }

  @override
  String remainingHours(int h) {
    return '$h시간 후';
  }

  @override
  String remainingHoursMinutes(int h, int m) {
    return '$h시간 $m분 후';
  }

  @override
  String get slotMorning => '아침';

  @override
  String get slotMidday => '낮';

  @override
  String get slotEvening => '저녁';

  @override
  String hypoCardTitle(int value, String time) {
    return '저혈당 $value · $time';
  }

  @override
  String get hypoCardSteps =>
      '1. 기운이 없거나 떨면 꿀·시럽을 잇몸에 바르세요.\n2. 15분 뒤 다시 재고, 경련·의식 저하가 있으면 바로 병원으로 가세요.\n3. 다음 인슐린은 수의사와 상의하기 전까지 투여하지 마세요.';

  @override
  String hypoCardVet(String name) {
    return '병원: $name';
  }

  @override
  String get setupPlanTitle => '투여 시간을 정해 주세요';

  @override
  String get setupPlanBody =>
      '정해 두면 다음 투여까지 남은 시간과 가족의 투여 현황을 보여 드리고, 같은 회차에 두 번 투여하지 않도록 막아 드려요.';

  @override
  String get setupPlanButton => '관리 계획 설정';

  @override
  String get doseDueNow => '지금 투여할 시간';

  @override
  String get doseNext => '다음 투여';

  @override
  String doseSlotLabel(String slot) {
    return '$slot 회차';
  }

  @override
  String get doseNoneToday => '오늘 아직 투여 기록이 없어요';

  @override
  String doseMissedSlot(String slot, String time) {
    return '$slot $time 회차 기록이 없어요';
  }

  @override
  String get doseRecordButton => '투여 기록하기';

  @override
  String doseGivenBy(String slot, String who, String time, String dose) {
    return '$slot $who $time에 $dose IU 투여 완료';
  }

  @override
  String latestGlucoseLabel(String time) {
    return '최신 혈당 · $time';
  }

  @override
  String glucoseVsYesterday(String delta) {
    return '어제 이맘때보다 $delta';
  }

  @override
  String get last48h => '최근 48시간';

  @override
  String otherPetNextDose(String time, String remaining) {
    return '다음 투여 $time · $remaining';
  }

  @override
  String get todayRecords => '오늘 기록';

  @override
  String todayGlucoseCount(int count) {
    return '혈당 $count회';
  }

  @override
  String get todayEmpty => '아직 오늘 기록이 없어요';

  @override
  String get viewPastRecords => '지난 기록 보기';

  @override
  String get weightLabel => '체중';

  @override
  String weightMeasuredOn(String date) {
    return '$date 측정';
  }

  @override
  String weightChangeSince(String date, String pct) {
    return '$date 대비 $pct';
  }

  @override
  String get noPetTitle => '아직 등록된 반려동물이 없어요';

  @override
  String get noPetBody => '강아지, 고양이 모두 등록할 수 있어요.\n건강수첩에서 우리 아이를 등록해 주세요.';

  @override
  String get noPetButton => '반려동물 등록하기';

  @override
  String get kindAll => '전체';

  @override
  String get kindGlucose => '혈당';

  @override
  String get kindInsulin => '인슐린';

  @override
  String get kindMeal => '식사';

  @override
  String get kindWeight => '체중';

  @override
  String get kindObservation => '관찰';

  @override
  String get trendsAddPetFirst => '반려동물을 먼저 등록해 주세요.';

  @override
  String trendsSubtitle(String from, String to) {
    return '추이 · $from – $to';
  }

  @override
  String trendsTarget(int min, int max) {
    return '목표 $min–$max';
  }

  @override
  String get trendsNoGlucose => '이 기간에 혈당 기록이 없어요';

  @override
  String get trendsRecords => '기록';

  @override
  String periodDays(int days) {
    return '$days일';
  }

  @override
  String get legendTarget => '목표 범위';

  @override
  String get legendReading => '측정값';

  @override
  String get legendHypo => '저혈당';

  @override
  String get legendDose => '투여';

  @override
  String get legendSkipped => '생략';

  @override
  String get tirTitle => '목표 범위 내 비율';

  @override
  String tirReadings(int count) {
    return '측정 $count회';
  }

  @override
  String get summaryTitle => '요약';

  @override
  String summaryComparedTo(int days) {
    return '직전 $days일과 비교';
  }

  @override
  String get summaryAverage => '평균';

  @override
  String get summaryLowest => '최저';

  @override
  String get summaryHighest => '최고';

  @override
  String weightTrendTrailing(String kg, String date, String pct) {
    return '$kg kg · $date 대비 $pct';
  }

  @override
  String get entryNothingToSave => '저장할 내용을 입력해 주세요.';

  @override
  String entryTitle(String name) {
    return '$name 기록 추가';
  }

  @override
  String get entryChangeTime => '시각 변경';

  @override
  String get entryGlucoseField => '혈당';

  @override
  String get entryInsulinUnset => '인슐린 미설정';

  @override
  String entryInsulinConcentration(String value) {
    return '인슐린 $value';
  }

  @override
  String entrySyringe(String value) {
    return '주사기 $value';
  }

  @override
  String get entryPen => '펜';

  @override
  String get entryMismatchTitle => '인슐린과 주사기 눈금이 달라요';

  @override
  String entryMismatchBody(String insulin, String syringe) {
    return '인슐린은 $insulin인데 주사기는 $syringe로 설정돼 있어요. 눈금대로 넣으면 실제 용량이 크게 달라집니다. 건강수첩의 관리 계획을 확인해 주세요.';
  }

  @override
  String get entryDoseField => '투여량';

  @override
  String get entryNotes => '메모';

  @override
  String get dupTitle => '이번 회차는 이미 투여됐어요';

  @override
  String dupBody(String who, String time, String dose) {
    return '$who $time에 $dose IU를 투여했다고 기록했어요. 한 번 더 투여하면 저혈당 위험이 있어요.';
  }

  @override
  String get dupAcknowledge => '확인했어요. 별도 투여가 맞아서 기록할게요.';

  @override
  String get insulinCaninsulin => '캐닌슐린';

  @override
  String get insulinLantus => '란투스';

  @override
  String get insulinLevemir => '레베미어';

  @override
  String get insulinProZinc => '프로징크';

  @override
  String get insulinNph => '휴물린N/노볼린N';

  @override
  String get insulinTresiba => '트레시바';

  @override
  String get insulinToujeo => '투제오';

  @override
  String get insulinOther => '기타';

  @override
  String get bookAddPet => '반려동물 등록하기';

  @override
  String get bookManagePets => '반려동물 관리';

  @override
  String get bookAddPetHint => '강아지, 고양이 모두 등록할 수 있어요';

  @override
  String get bookManagePetsHint => '등록 · 정보 수정 · 삭제 · 초대 코드';

  @override
  String get sexMale => '수컷';

  @override
  String get sexFemale => '암컷';

  @override
  String get sexMaleNeutered => '수컷(중성화)';

  @override
  String get sexFemaleSpayed => '암컷(중성화)';

  @override
  String ageYears(int years) {
    return '$years살';
  }

  @override
  String diagnosedOn(String date) {
    return '$date 진단';
  }

  @override
  String get planTitle => '당뇨 관리 계획';

  @override
  String get planInsulin => '인슐린';

  @override
  String get planDoseTimes => '용량 · 시각';

  @override
  String get planTimesUnset => '투여 시각 미설정';

  @override
  String get planSyringe => '주사기';

  @override
  String get planTarget => '목표 혈당';

  @override
  String planTargetValue(int min, int max, int hypo) {
    return '$min – $max · 저혈당 $hypo 미만';
  }

  @override
  String get planMeter => '측정기';

  @override
  String get planFood => '사료';

  @override
  String get planVet => '병원';

  @override
  String get conditionTitle => '질환 관리';

  @override
  String conditionBody(String name) {
    return '$name이(가) 당뇨 진단을 받았다면 관리 계획을 만들어 투여 시간, 혈당 목표, 가족 간 중복 투여 방지를 시작할 수 있어요.';
  }

  @override
  String get conditionStartDiabetes => '당뇨 관리 시작';

  @override
  String planSheetTitle(String name) {
    return '$name 당뇨 관리 계획';
  }

  @override
  String get planErrRange => '목표 범위를 확인해 주세요. 하한이 상한보다 작아야 해요.';

  @override
  String get planErrHypo => '저혈당 기준은 40–150 사이로 입력해 주세요.';

  @override
  String get planErrSave => '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get planDosingTimes => '투여 시각';

  @override
  String get planAddTime => '시각 추가';

  @override
  String get planTwiceDaily => '07:00 · 19:00 (하루 2회)';

  @override
  String get planInsulinType => '종류';

  @override
  String get planInsulinName => '인슐린 이름';

  @override
  String get planDosePerShot => '1회 용량';

  @override
  String get planConcentration => '인슐린 농도';

  @override
  String planMismatch(String insulin, String syringe) {
    return '인슐린($insulin)과 주사기($syringe) 눈금이 달라요. 눈금대로 넣으면 실제 용량이 크게 달라집니다.';
  }

  @override
  String get planLower => '하한';

  @override
  String get planUpper => '상한';

  @override
  String get planHypoThreshold => '저혈당 기준';

  @override
  String get planTargetHint =>
      '수의사가 정해 준 범위를 넣어 주세요. 기본값은 강아지 100–250, 고양이 100–300입니다.';

  @override
  String get planMeterFoodVet => '측정기 · 사료 · 병원';

  @override
  String get planMeterHint => '혈당 측정기 (예: 알파트랙 3)';

  @override
  String get planDefaultWet => '기본 습식 사료';

  @override
  String get planDefaultDry => '기본 건식 사료';

  @override
  String get planVetClinic => '다니는 병원';

  @override
  String get errUnknown => '문제가 생겼어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get errGoogleToken => '구글 ID 토큰을 찾을 수 없습니다. 다시 시도해주세요.';

  @override
  String get errGoogleSignIn => '구글 로그인에 실패했습니다. 다시 시도해주세요.';

  @override
  String get errAppleToken => '애플 ID 토큰을 찾을 수 없습니다.';

  @override
  String get errAppleSignIn => '애플 로그인에 실패했습니다. 다시 시도해주세요.';

  @override
  String get errNotSignedIn => '로그인이 필요합니다.';

  @override
  String get errDeleteAccount => '회원탈퇴에 실패했습니다. 데이터를 다시 확인해주세요.';

  @override
  String get errInviteCreate => '초대 코드를 생성할 수 없습니다. 네트워크를 확인해주세요.';

  @override
  String get errInviteInvalid => '유효하지 않은 초대 코드입니다.';

  @override
  String get errInviteExpired => '만료된 초대 코드입니다.';

  @override
  String get errInviteAlreadyJoined => '이미 연결된 가족입니다.';

  @override
  String get errJoinFailed => '가족 참여에 실패했습니다. 네트워크를 확인해주세요.';

  @override
  String get errRecordNotFound => '기록을 찾을 수 없거나 삭제할 권한이 없습니다.';

  @override
  String get errSaveFailed => '저장에 실패했습니다.';

  @override
  String get petDeleteTitle => '반려동물 삭제';

  @override
  String get petLeaveTitle => '가족 나가기';

  @override
  String petDeleteBody(String name) {
    return '$name의 모든 데이터를 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String petLeaveBody(String name) {
    return '$name의 가족 공간에서 나가시겠습니까?';
  }

  @override
  String get petDeleted => '삭제되었습니다.';

  @override
  String get petLeft => '가족에서 나왔습니다.';

  @override
  String get petLeave => '나가기';

  @override
  String get petManageTitle => '반려동물 관리';

  @override
  String get petAddTooltip => '새 반려동물 등록';

  @override
  String get petNewTitle => '새로운 반려동물 등록';

  @override
  String get petBasicInfo => '기본 정보';

  @override
  String get petName => '이름';

  @override
  String get petNameRequired => '이름을 입력하세요';

  @override
  String get petSpecies => '종류';

  @override
  String get petSex => '성별';

  @override
  String get petBreedOptional => '품종 (선택)';

  @override
  String get petNeutered => '중성화 완료';

  @override
  String get petHealthInfo => '건강 및 관리 정보';

  @override
  String get petWeightKg => '체중 (kg)';

  @override
  String get petWeightInvalid => '올바른 체중을 입력하세요 (0 초과, 150 이하)';

  @override
  String get petInsulinTypeOptional => '인슐린 종류 (선택)';

  @override
  String get petInsulinOther => '기타 인슐린 직접 입력';

  @override
  String get petInsulinUnits => '단위 (IU)';

  @override
  String get petInsulinUnitsInvalid => '올바른 단위(IU)를 입력하세요 (0 초과, 150 이하)';

  @override
  String get petTargetGlucose => '목표 혈당 설정';

  @override
  String get petSaveAndStart => '저장하고 시작하기';

  @override
  String get roleOwner => '보호자';

  @override
  String get roleCoCaregiver => '공동양육자';

  @override
  String get breedUnknown => '품종 모름';

  @override
  String get familySharing => '가족 공유';

  @override
  String get inviteCreate => '초대 코드 발급';

  @override
  String get inviteCodeTitle => '초대 코드';

  @override
  String get inviteCodeBody => '아래 코드를 복사하여 가족에게 전달하세요.\n코드는 24시간 동안 유효합니다.';

  @override
  String get inviteCopy => '복사하기';

  @override
  String get inviteCopied => '초대 코드가 복사되었습니다.';

  @override
  String get familyJoinTitle => '가족 참여하기';

  @override
  String get familyJoinPrompt => '전달받은 6자리 초대 코드를 입력하세요.';

  @override
  String get familyInviteCodeLabel => '초대 코드';

  @override
  String get familyCodeRequired => '6자리 코드를 입력해주세요.';

  @override
  String get familyJoined => '가족에 성공적으로 참여했습니다.';

  @override
  String get familyJoin => '참여';

  @override
  String get familyTitle => '가족 관리 (공동 양육자)';

  @override
  String get familyIntro => '반려동물 데이터를 가족과 함께 실시간으로 공유하고 관리하세요.';

  @override
  String get familyInviteTitle => '가족 초대하기';

  @override
  String familyInviteBody(String name) {
    return '현재 선택된 반려동물($name)의 공간에 파트너를 초대합니다. 생성된 코드는 24시간 동안 유효합니다.';
  }

  @override
  String get familyGetCode => '초대 코드 발급받기';

  @override
  String get familyJoinBody => '가족에게 전달받은 6자리 초대 코드가 있다면 아래 버튼을 눌러 입력하세요.';

  @override
  String get familyEnterCode => '초대 코드 입력';

  @override
  String get settingsAppInfo => '앱 정보 및 설정';

  @override
  String get settingsVersion => '버전 정보';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsPrivacy => '개인정보처리방침';

  @override
  String get settingsLicenses => '오픈소스 라이선스';

  @override
  String get settingsCannotOpenBrowser => '웹 브라우저를 열 수 없습니다.';

  @override
  String get settingsDeleteAccount => '회원 탈퇴';

  @override
  String get settingsDeleteAccountBody =>
      '정말로 Mettie 앱을 탈퇴하시겠습니까?\n기록된 모든 반려동물 데이터와 개인정보가 즉시 삭제되며 복구할 수 없습니다.';

  @override
  String get settingsDeleteAccountConfirm => '탈퇴하기';

  @override
  String get accountInfo => '계정 정보';

  @override
  String get accountDefaultName => '사용자';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get rowOther => '기타';

  @override
  String get rowMorning => '아침';

  @override
  String get rowLunch => '점심';

  @override
  String get rowEvening => '저녁';

  @override
  String get rowNight => '야간';

  @override
  String rowPreMeal(String time) {
    return '$time 식전';
  }

  @override
  String rowPostMeal(String time) {
    return '$time 식후';
  }

  @override
  String get rowFasting => '공복';

  @override
  String get rowNadir => '최저 혈당(Nadir)';

  @override
  String rowInsulin(String time) {
    return '$time 인슐린';
  }

  @override
  String rowMeal(String time) {
    return '$time 식사';
  }

  @override
  String get rowDeleteTitle => '기록 삭제';

  @override
  String get rowDeleteBody => '이 기록을 정말 삭제하시겠습니까?\n삭제된 기록은 다시 복구할 수 없습니다.';

  @override
  String get rowDeleted => '기록이 삭제되었습니다.';

  @override
  String get rowFood => '사료';

  @override
  String get selectorTitle => '반려동물 선택';

  @override
  String get selectorEmpty => '등록된 반려동물이 없습니다.';

  @override
  String get selectorDeleteAction => '삭제하기';

  @override
  String get loginHeadline => '우리 아이 혈당 기록\n스마트한 AI 가이드';

  @override
  String get loginSubtitle => '간편한 혈당 체크부터 일상 기록까지\nMettie AI가 도와드립니다.';

  @override
  String get loginWithEmail => '이메일로 계속하기';

  @override
  String get loginOr => '또는';

  @override
  String get loginWithApple => 'Apple로 계속하기';

  @override
  String get loginWithGoogle => 'Google로 계속하기';

  @override
  String get emailAgreeRequired => '이용약관 및 개인정보처리방침에 동의해주세요.';

  @override
  String get emailVerifyTitle => '이메일 인증 안내';

  @override
  String get emailLinkSent => '회원가입 링크가 전송되었습니다.';

  @override
  String emailSentTo(String email) {
    return '$email 이메일로 가입 승인을 위한 링크를 발송했습니다.';
  }

  @override
  String get emailCheckInbox =>
      '수신된 이메일의 링크를 클릭하시면 회원가입이 완료됩니다. (스팸 메일함도 함께 확인해주세요.)';

  @override
  String get emailSignUpTitle => '이메일 회원가입';

  @override
  String get emailSignInTitle => '이메일 로그인';

  @override
  String get emailNameHint => '이름을 입력하세요';

  @override
  String get emailName => '이름';

  @override
  String get emailNameRequired => '이름을 입력해주세요.';

  @override
  String get emailEmail => '이메일';

  @override
  String get emailEmailRequired => '이메일을 입력해주세요.';

  @override
  String get emailEmailInvalid => '올바른 이메일 형식이 아닙니다.';

  @override
  String get emailPasswordHint => '비밀번호를 입력하세요 (6자 이상)';

  @override
  String get emailPassword => '비밀번호';

  @override
  String get emailPasswordRequired => '비밀번호를 입력해주세요.';

  @override
  String get emailPasswordTooShort => '비밀번호는 최소 6자 이상이어야 합니다.';

  @override
  String termsAgreement(String terms, String privacy) {
    return 'Mettie의 $terms 및 $privacy에 동의합니다.';
  }

  @override
  String get emailSignUpButton => '이메일로 회원가입';

  @override
  String get emailSignInButton => '이메일로 로그인';

  @override
  String get emailHaveAccount => '이미 계정이 있으신가요? 로그인';

  @override
  String get emailNoAccount => '계정이 없으신가요? 회원가입';
}
