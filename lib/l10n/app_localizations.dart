import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'메티'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonSaveCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 저장'**
  String commonSaveCount(int count);

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @commonSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get commonSettings;

  /// No description provided for @commonUnset.
  ///
  /// In ko, this message translates to:
  /// **'미설정'**
  String get commonUnset;

  /// No description provided for @commonAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get commonAdd;

  /// No description provided for @commonMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get commonMe;

  /// No description provided for @commonFamily.
  ///
  /// In ko, this message translates to:
  /// **'가족'**
  String get commonFamily;

  /// No description provided for @commonNetworkError.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.'**
  String get commonNetworkError;

  /// No description provided for @commonLoadError.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오지 못했습니다.'**
  String get commonLoadError;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navTrends.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get navTrends;

  /// No description provided for @navCoach.
  ///
  /// In ko, this message translates to:
  /// **'AI 코치'**
  String get navCoach;

  /// No description provided for @navBook.
  ///
  /// In ko, this message translates to:
  /// **'건강수첩'**
  String get navBook;

  /// No description provided for @navAddRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록 추가'**
  String get navAddRecord;

  /// No description provided for @needPetFirstForRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록을 추가하려면 먼저 반려동물을 등록해주세요.'**
  String get needPetFirstForRecord;

  /// No description provided for @switchPet.
  ///
  /// In ko, this message translates to:
  /// **'반려동물 바꾸기'**
  String get switchPet;

  /// No description provided for @unitMgdl.
  ///
  /// In ko, this message translates to:
  /// **'mg/dL'**
  String get unitMgdl;

  /// No description provided for @unitIu.
  ///
  /// In ko, this message translates to:
  /// **'IU'**
  String get unitIu;

  /// No description provided for @unitG.
  ///
  /// In ko, this message translates to:
  /// **'g'**
  String get unitG;

  /// No description provided for @unitKg.
  ///
  /// In ko, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @speciesDog.
  ///
  /// In ko, this message translates to:
  /// **'강아지'**
  String get speciesDog;

  /// No description provided for @speciesCat.
  ///
  /// In ko, this message translates to:
  /// **'고양이'**
  String get speciesCat;

  /// No description provided for @glucoseHypo.
  ///
  /// In ko, this message translates to:
  /// **'저혈당'**
  String get glucoseHypo;

  /// No description provided for @glucoseLow.
  ///
  /// In ko, this message translates to:
  /// **'낮음'**
  String get glucoseLow;

  /// No description provided for @glucoseInRange.
  ///
  /// In ko, this message translates to:
  /// **'목표 범위'**
  String get glucoseInRange;

  /// No description provided for @glucoseHigh.
  ///
  /// In ko, this message translates to:
  /// **'높음'**
  String get glucoseHigh;

  /// No description provided for @glucoseVeryHigh.
  ///
  /// In ko, this message translates to:
  /// **'매우 높음'**
  String get glucoseVeryHigh;

  /// No description provided for @glucoseTypePreMeal.
  ///
  /// In ko, this message translates to:
  /// **'식전'**
  String get glucoseTypePreMeal;

  /// No description provided for @glucoseTypePostMeal.
  ///
  /// In ko, this message translates to:
  /// **'식후'**
  String get glucoseTypePostMeal;

  /// No description provided for @glucoseTypeFasting.
  ///
  /// In ko, this message translates to:
  /// **'공복'**
  String get glucoseTypeFasting;

  /// No description provided for @glucoseTypeNadir.
  ///
  /// In ko, this message translates to:
  /// **'nadir'**
  String get glucoseTypeNadir;

  /// No description provided for @glucoseTypeSpot.
  ///
  /// In ko, this message translates to:
  /// **'임의'**
  String get glucoseTypeSpot;

  /// No description provided for @foodWet.
  ///
  /// In ko, this message translates to:
  /// **'습식'**
  String get foodWet;

  /// No description provided for @foodDry.
  ///
  /// In ko, this message translates to:
  /// **'건식'**
  String get foodDry;

  /// No description provided for @foodRaw.
  ///
  /// In ko, this message translates to:
  /// **'생식'**
  String get foodRaw;

  /// No description provided for @foodMixed.
  ///
  /// In ko, this message translates to:
  /// **'혼합'**
  String get foodMixed;

  /// No description provided for @foodGeneric.
  ///
  /// In ko, this message translates to:
  /// **'사료'**
  String get foodGeneric;

  /// No description provided for @appetiteGood.
  ///
  /// In ko, this message translates to:
  /// **'잘 먹음'**
  String get appetiteGood;

  /// No description provided for @appetitePartial.
  ///
  /// In ko, this message translates to:
  /// **'조금 남김'**
  String get appetitePartial;

  /// No description provided for @appetiteNone.
  ///
  /// In ko, this message translates to:
  /// **'안 먹음'**
  String get appetiteNone;

  /// No description provided for @appetitePoor.
  ///
  /// In ko, this message translates to:
  /// **'식욕 저하'**
  String get appetitePoor;

  /// No description provided for @injectionGiven.
  ///
  /// In ko, this message translates to:
  /// **'투여 완료'**
  String get injectionGiven;

  /// No description provided for @injectionPartial.
  ///
  /// In ko, this message translates to:
  /// **'일부 투여'**
  String get injectionPartial;

  /// No description provided for @injectionSkipped.
  ///
  /// In ko, this message translates to:
  /// **'생략'**
  String get injectionSkipped;

  /// No description provided for @obsDrinkMore.
  ///
  /// In ko, this message translates to:
  /// **'물 많이 마심'**
  String get obsDrinkMore;

  /// No description provided for @obsDrinkLess.
  ///
  /// In ko, this message translates to:
  /// **'물 적게 마심'**
  String get obsDrinkLess;

  /// No description provided for @obsUrinateMore.
  ///
  /// In ko, this message translates to:
  /// **'소변 많음'**
  String get obsUrinateMore;

  /// No description provided for @obsUrinateLess.
  ///
  /// In ko, this message translates to:
  /// **'소변 적음'**
  String get obsUrinateLess;

  /// No description provided for @obsNoAppetite.
  ///
  /// In ko, this message translates to:
  /// **'식욕 없음'**
  String get obsNoAppetite;

  /// No description provided for @obsVomit.
  ///
  /// In ko, this message translates to:
  /// **'구토'**
  String get obsVomit;

  /// No description provided for @obsVomitCount.
  ///
  /// In ko, this message translates to:
  /// **'구토 {count}회'**
  String obsVomitCount(int count);

  /// No description provided for @obsDiarrhea.
  ///
  /// In ko, this message translates to:
  /// **'설사'**
  String get obsDiarrhea;

  /// No description provided for @obsConstipation.
  ///
  /// In ko, this message translates to:
  /// **'변비'**
  String get obsConstipation;

  /// No description provided for @obsLethargy.
  ///
  /// In ko, this message translates to:
  /// **'무기력'**
  String get obsLethargy;

  /// No description provided for @obsWalkMore.
  ///
  /// In ko, this message translates to:
  /// **'산책 평소보다 많음'**
  String get obsWalkMore;

  /// No description provided for @obsWalkLess.
  ///
  /// In ko, this message translates to:
  /// **'산책 평소보다 적음'**
  String get obsWalkLess;

  /// No description provided for @obsEyeCloudy.
  ///
  /// In ko, this message translates to:
  /// **'눈 혼탁·시야 이상'**
  String get obsEyeCloudy;

  /// No description provided for @obsLitterLarge.
  ///
  /// In ko, this message translates to:
  /// **'화장실 덩어리 큼'**
  String get obsLitterLarge;

  /// No description provided for @obsHindGait.
  ///
  /// In ko, this message translates to:
  /// **'뒷다리 걸음 이상'**
  String get obsHindGait;

  /// 문장 주어로 쓰는 '나'
  ///
  /// In ko, this message translates to:
  /// **'내가'**
  String get writerSubjectMe;

  /// 문장 주어로 쓰는 가족 이름. 한국어 조사는 코드에서 붙인다
  ///
  /// In ko, this message translates to:
  /// **'{name}'**
  String writerSubjectOther(String name);

  /// No description provided for @tlInsulin.
  ///
  /// In ko, this message translates to:
  /// **'인슐린 {dose} IU'**
  String tlInsulin(String dose);

  /// No description provided for @tlInsulinPartial.
  ///
  /// In ko, this message translates to:
  /// **'인슐린 일부 {dose} IU'**
  String tlInsulinPartial(String dose);

  /// No description provided for @tlInsulinSkipped.
  ///
  /// In ko, this message translates to:
  /// **'인슐린 생략'**
  String get tlInsulinSkipped;

  /// No description provided for @tlGlucose.
  ///
  /// In ko, this message translates to:
  /// **'혈당 {value}'**
  String tlGlucose(int value);

  /// No description provided for @tlFoodAmount.
  ///
  /// In ko, this message translates to:
  /// **'사료 {grams} g'**
  String tlFoodAmount(String grams);

  /// No description provided for @tlWeight.
  ///
  /// In ko, this message translates to:
  /// **'체중 {kg} kg'**
  String tlWeight(String kg);

  /// No description provided for @tlEmptyFiltered.
  ///
  /// In ko, this message translates to:
  /// **'이 조건의 기록이 없습니다.'**
  String get tlEmptyFiltered;

  /// No description provided for @tlToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get tlToday;

  /// No description provided for @tlHypoCount.
  ///
  /// In ko, this message translates to:
  /// **'저혈당 {count}회'**
  String tlHypoCount(int count);

  /// No description provided for @tlDoses.
  ///
  /// In ko, this message translates to:
  /// **'투여 {given}/{planned}'**
  String tlDoses(int given, int planned);

  /// No description provided for @tlSkippedCount.
  ///
  /// In ko, this message translates to:
  /// **'생략 {count}'**
  String tlSkippedCount(int count);

  /// No description provided for @tlGlucoseSingle.
  ///
  /// In ko, this message translates to:
  /// **'혈당 {value}'**
  String tlGlucoseSingle(int value);

  /// No description provided for @tlGlucoseAverage.
  ///
  /// In ko, this message translates to:
  /// **'혈당 평균 {value}'**
  String tlGlucoseAverage(int value);

  /// No description provided for @todayDiagnosisDay.
  ///
  /// In ko, this message translates to:
  /// **'진단 {days}일째'**
  String todayDiagnosisDay(int days);

  /// No description provided for @remainingSoon.
  ///
  /// In ko, this message translates to:
  /// **'곧'**
  String get remainingSoon;

  /// No description provided for @remainingMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{m}분 후'**
  String remainingMinutes(int m);

  /// No description provided for @remainingHours.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 후'**
  String remainingHours(int h);

  /// No description provided for @remainingHoursMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분 후'**
  String remainingHoursMinutes(int h, int m);

  /// No description provided for @slotMorning.
  ///
  /// In ko, this message translates to:
  /// **'아침'**
  String get slotMorning;

  /// No description provided for @slotMidday.
  ///
  /// In ko, this message translates to:
  /// **'낮'**
  String get slotMidday;

  /// No description provided for @slotEvening.
  ///
  /// In ko, this message translates to:
  /// **'저녁'**
  String get slotEvening;

  /// No description provided for @hypoCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'저혈당 {value} · {time}'**
  String hypoCardTitle(int value, String time);

  /// No description provided for @hypoCardSteps.
  ///
  /// In ko, this message translates to:
  /// **'1. 기운이 없거나 떨면 꿀·시럽을 잇몸에 바르세요.\n2. 15분 뒤 다시 재고, 경련·의식 저하가 있으면 바로 병원으로 가세요.\n3. 다음 인슐린은 수의사와 상의하기 전까지 투여하지 마세요.'**
  String get hypoCardSteps;

  /// No description provided for @hypoCardVet.
  ///
  /// In ko, this message translates to:
  /// **'병원: {name}'**
  String hypoCardVet(String name);

  /// No description provided for @setupPlanTitle.
  ///
  /// In ko, this message translates to:
  /// **'투여 시간을 정해 주세요'**
  String get setupPlanTitle;

  /// No description provided for @setupPlanBody.
  ///
  /// In ko, this message translates to:
  /// **'정해 두면 다음 투여까지 남은 시간과 가족의 투여 현황을 보여 드리고, 같은 회차에 두 번 투여하지 않도록 막아 드려요.'**
  String get setupPlanBody;

  /// No description provided for @setupPlanButton.
  ///
  /// In ko, this message translates to:
  /// **'관리 계획 설정'**
  String get setupPlanButton;

  /// No description provided for @doseDueNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 투여할 시간'**
  String get doseDueNow;

  /// No description provided for @doseNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 투여'**
  String get doseNext;

  /// No description provided for @doseSlotLabel.
  ///
  /// In ko, this message translates to:
  /// **'{slot} 회차'**
  String doseSlotLabel(String slot);

  /// No description provided for @doseNoneToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 아직 투여 기록이 없어요'**
  String get doseNoneToday;

  /// No description provided for @doseMissedSlot.
  ///
  /// In ko, this message translates to:
  /// **'{slot} {time} 회차 기록이 없어요'**
  String doseMissedSlot(String slot, String time);

  /// No description provided for @doseRecordButton.
  ///
  /// In ko, this message translates to:
  /// **'투여 기록하기'**
  String get doseRecordButton;

  /// No description provided for @doseGivenBy.
  ///
  /// In ko, this message translates to:
  /// **'{slot} {who} {time}에 {dose} IU 투여 완료'**
  String doseGivenBy(String slot, String who, String time, String dose);

  /// No description provided for @latestGlucoseLabel.
  ///
  /// In ko, this message translates to:
  /// **'최신 혈당 · {time}'**
  String latestGlucoseLabel(String time);

  /// No description provided for @glucoseVsYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제 이맘때보다 {delta}'**
  String glucoseVsYesterday(String delta);

  /// No description provided for @last48h.
  ///
  /// In ko, this message translates to:
  /// **'최근 48시간'**
  String get last48h;

  /// No description provided for @otherPetNextDose.
  ///
  /// In ko, this message translates to:
  /// **'다음 투여 {time} · {remaining}'**
  String otherPetNextDose(String time, String remaining);

  /// No description provided for @todayRecords.
  ///
  /// In ko, this message translates to:
  /// **'오늘 기록'**
  String get todayRecords;

  /// No description provided for @todayGlucoseCount.
  ///
  /// In ko, this message translates to:
  /// **'혈당 {count}회'**
  String todayGlucoseCount(int count);

  /// No description provided for @todayEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 오늘 기록이 없어요'**
  String get todayEmpty;

  /// No description provided for @viewPastRecords.
  ///
  /// In ko, this message translates to:
  /// **'지난 기록 보기'**
  String get viewPastRecords;

  /// No description provided for @weightLabel.
  ///
  /// In ko, this message translates to:
  /// **'체중'**
  String get weightLabel;

  /// No description provided for @weightMeasuredOn.
  ///
  /// In ko, this message translates to:
  /// **'{date} 측정'**
  String weightMeasuredOn(String date);

  /// No description provided for @weightChangeSince.
  ///
  /// In ko, this message translates to:
  /// **'{date} 대비 {pct}'**
  String weightChangeSince(String date, String pct);

  /// No description provided for @noPetTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 반려동물이 없어요'**
  String get noPetTitle;

  /// No description provided for @noPetBody.
  ///
  /// In ko, this message translates to:
  /// **'강아지, 고양이 모두 등록할 수 있어요.\n건강수첩에서 우리 아이를 등록해 주세요.'**
  String get noPetBody;

  /// No description provided for @noPetButton.
  ///
  /// In ko, this message translates to:
  /// **'반려동물 등록하기'**
  String get noPetButton;

  /// No description provided for @kindAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get kindAll;

  /// No description provided for @kindGlucose.
  ///
  /// In ko, this message translates to:
  /// **'혈당'**
  String get kindGlucose;

  /// No description provided for @kindInsulin.
  ///
  /// In ko, this message translates to:
  /// **'인슐린'**
  String get kindInsulin;

  /// No description provided for @kindMeal.
  ///
  /// In ko, this message translates to:
  /// **'식사'**
  String get kindMeal;

  /// No description provided for @kindWeight.
  ///
  /// In ko, this message translates to:
  /// **'체중'**
  String get kindWeight;

  /// No description provided for @kindObservation.
  ///
  /// In ko, this message translates to:
  /// **'관찰'**
  String get kindObservation;

  /// No description provided for @trendsAddPetFirst.
  ///
  /// In ko, this message translates to:
  /// **'반려동물을 먼저 등록해 주세요.'**
  String get trendsAddPetFirst;

  /// No description provided for @trendsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'추이 · {from} – {to}'**
  String trendsSubtitle(String from, String to);

  /// No description provided for @trendsTarget.
  ///
  /// In ko, this message translates to:
  /// **'목표 {min}–{max}'**
  String trendsTarget(int min, int max);

  /// No description provided for @trendsNoGlucose.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 혈당 기록이 없어요'**
  String get trendsNoGlucose;

  /// No description provided for @trendsRecords.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get trendsRecords;

  /// No description provided for @periodDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String periodDays(int days);

  /// No description provided for @legendTarget.
  ///
  /// In ko, this message translates to:
  /// **'목표 범위'**
  String get legendTarget;

  /// No description provided for @legendReading.
  ///
  /// In ko, this message translates to:
  /// **'측정값'**
  String get legendReading;

  /// No description provided for @legendHypo.
  ///
  /// In ko, this message translates to:
  /// **'저혈당'**
  String get legendHypo;

  /// No description provided for @legendDose.
  ///
  /// In ko, this message translates to:
  /// **'투여'**
  String get legendDose;

  /// No description provided for @legendSkipped.
  ///
  /// In ko, this message translates to:
  /// **'생략'**
  String get legendSkipped;

  /// No description provided for @tirTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표 범위 내 비율'**
  String get tirTitle;

  /// No description provided for @tirReadings.
  ///
  /// In ko, this message translates to:
  /// **'측정 {count}회'**
  String tirReadings(int count);

  /// No description provided for @summaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'요약'**
  String get summaryTitle;

  /// No description provided for @summaryComparedTo.
  ///
  /// In ko, this message translates to:
  /// **'직전 {days}일과 비교'**
  String summaryComparedTo(int days);

  /// No description provided for @summaryAverage.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get summaryAverage;

  /// No description provided for @summaryLowest.
  ///
  /// In ko, this message translates to:
  /// **'최저'**
  String get summaryLowest;

  /// No description provided for @summaryHighest.
  ///
  /// In ko, this message translates to:
  /// **'최고'**
  String get summaryHighest;

  /// No description provided for @weightTrendTrailing.
  ///
  /// In ko, this message translates to:
  /// **'{kg} kg · {date} 대비 {pct}'**
  String weightTrendTrailing(String kg, String date, String pct);

  /// No description provided for @entryNothingToSave.
  ///
  /// In ko, this message translates to:
  /// **'저장할 내용을 입력해 주세요.'**
  String get entryNothingToSave;

  /// No description provided for @entryTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 기록 추가'**
  String entryTitle(String name);

  /// No description provided for @entryChangeTime.
  ///
  /// In ko, this message translates to:
  /// **'시각 변경'**
  String get entryChangeTime;

  /// No description provided for @entryGlucoseField.
  ///
  /// In ko, this message translates to:
  /// **'혈당'**
  String get entryGlucoseField;

  /// No description provided for @entryInsulinUnset.
  ///
  /// In ko, this message translates to:
  /// **'인슐린 미설정'**
  String get entryInsulinUnset;

  /// No description provided for @entryInsulinConcentration.
  ///
  /// In ko, this message translates to:
  /// **'인슐린 {value}'**
  String entryInsulinConcentration(String value);

  /// No description provided for @entrySyringe.
  ///
  /// In ko, this message translates to:
  /// **'주사기 {value}'**
  String entrySyringe(String value);

  /// No description provided for @entryPen.
  ///
  /// In ko, this message translates to:
  /// **'펜'**
  String get entryPen;

  /// No description provided for @entryMismatchTitle.
  ///
  /// In ko, this message translates to:
  /// **'인슐린과 주사기 눈금이 달라요'**
  String get entryMismatchTitle;

  /// No description provided for @entryMismatchBody.
  ///
  /// In ko, this message translates to:
  /// **'인슐린은 {insulin}인데 주사기는 {syringe}로 설정돼 있어요. 눈금대로 넣으면 실제 용량이 크게 달라집니다. 건강수첩의 관리 계획을 확인해 주세요.'**
  String entryMismatchBody(String insulin, String syringe);

  /// No description provided for @entryDoseField.
  ///
  /// In ko, this message translates to:
  /// **'투여량'**
  String get entryDoseField;

  /// No description provided for @entryNotes.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get entryNotes;

  /// No description provided for @dupTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 회차는 이미 투여됐어요'**
  String get dupTitle;

  /// No description provided for @dupBody.
  ///
  /// In ko, this message translates to:
  /// **'{who} {time}에 {dose} IU를 투여했다고 기록했어요. 한 번 더 투여하면 저혈당 위험이 있어요.'**
  String dupBody(String who, String time, String dose);

  /// No description provided for @dupAcknowledge.
  ///
  /// In ko, this message translates to:
  /// **'확인했어요. 별도 투여가 맞아서 기록할게요.'**
  String get dupAcknowledge;

  /// No description provided for @insulinCaninsulin.
  ///
  /// In ko, this message translates to:
  /// **'캐닌슐린'**
  String get insulinCaninsulin;

  /// No description provided for @insulinLantus.
  ///
  /// In ko, this message translates to:
  /// **'란투스'**
  String get insulinLantus;

  /// No description provided for @insulinLevemir.
  ///
  /// In ko, this message translates to:
  /// **'레베미어'**
  String get insulinLevemir;

  /// No description provided for @insulinProZinc.
  ///
  /// In ko, this message translates to:
  /// **'프로징크'**
  String get insulinProZinc;

  /// No description provided for @insulinNph.
  ///
  /// In ko, this message translates to:
  /// **'휴물린N/노볼린N'**
  String get insulinNph;

  /// No description provided for @insulinTresiba.
  ///
  /// In ko, this message translates to:
  /// **'트레시바'**
  String get insulinTresiba;

  /// No description provided for @insulinToujeo.
  ///
  /// In ko, this message translates to:
  /// **'투제오'**
  String get insulinToujeo;

  /// No description provided for @insulinOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get insulinOther;

  /// No description provided for @bookAddPet.
  ///
  /// In ko, this message translates to:
  /// **'반려동물 등록하기'**
  String get bookAddPet;

  /// No description provided for @bookManagePets.
  ///
  /// In ko, this message translates to:
  /// **'반려동물 관리'**
  String get bookManagePets;

  /// No description provided for @bookAddPetHint.
  ///
  /// In ko, this message translates to:
  /// **'강아지, 고양이 모두 등록할 수 있어요'**
  String get bookAddPetHint;

  /// No description provided for @bookManagePetsHint.
  ///
  /// In ko, this message translates to:
  /// **'등록 · 정보 수정 · 삭제 · 초대 코드'**
  String get bookManagePetsHint;

  /// No description provided for @sexMale.
  ///
  /// In ko, this message translates to:
  /// **'수컷'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In ko, this message translates to:
  /// **'암컷'**
  String get sexFemale;

  /// No description provided for @sexMaleNeutered.
  ///
  /// In ko, this message translates to:
  /// **'수컷(중성화)'**
  String get sexMaleNeutered;

  /// No description provided for @sexFemaleSpayed.
  ///
  /// In ko, this message translates to:
  /// **'암컷(중성화)'**
  String get sexFemaleSpayed;

  /// No description provided for @ageYears.
  ///
  /// In ko, this message translates to:
  /// **'{years}살'**
  String ageYears(int years);

  /// No description provided for @diagnosedOn.
  ///
  /// In ko, this message translates to:
  /// **'{date} 진단'**
  String diagnosedOn(String date);

  /// No description provided for @planTitle.
  ///
  /// In ko, this message translates to:
  /// **'당뇨 관리 계획'**
  String get planTitle;

  /// No description provided for @planInsulin.
  ///
  /// In ko, this message translates to:
  /// **'인슐린'**
  String get planInsulin;

  /// No description provided for @planDoseTimes.
  ///
  /// In ko, this message translates to:
  /// **'용량 · 시각'**
  String get planDoseTimes;

  /// No description provided for @planTimesUnset.
  ///
  /// In ko, this message translates to:
  /// **'투여 시각 미설정'**
  String get planTimesUnset;

  /// No description provided for @planSyringe.
  ///
  /// In ko, this message translates to:
  /// **'주사기'**
  String get planSyringe;

  /// No description provided for @planTarget.
  ///
  /// In ko, this message translates to:
  /// **'목표 혈당'**
  String get planTarget;

  /// No description provided for @planTargetValue.
  ///
  /// In ko, this message translates to:
  /// **'{min} – {max} · 저혈당 {hypo} 미만'**
  String planTargetValue(int min, int max, int hypo);

  /// No description provided for @planMeter.
  ///
  /// In ko, this message translates to:
  /// **'측정기'**
  String get planMeter;

  /// No description provided for @planFood.
  ///
  /// In ko, this message translates to:
  /// **'사료'**
  String get planFood;

  /// No description provided for @planVet.
  ///
  /// In ko, this message translates to:
  /// **'병원'**
  String get planVet;

  /// No description provided for @conditionTitle.
  ///
  /// In ko, this message translates to:
  /// **'질환 관리'**
  String get conditionTitle;

  /// No description provided for @conditionBody.
  ///
  /// In ko, this message translates to:
  /// **'{name}이(가) 당뇨 진단을 받았다면 관리 계획을 만들어 투여 시간, 혈당 목표, 가족 간 중복 투여 방지를 시작할 수 있어요.'**
  String conditionBody(String name);

  /// No description provided for @conditionStartDiabetes.
  ///
  /// In ko, this message translates to:
  /// **'당뇨 관리 시작'**
  String get conditionStartDiabetes;

  /// No description provided for @planSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 당뇨 관리 계획'**
  String planSheetTitle(String name);

  /// No description provided for @planErrRange.
  ///
  /// In ko, this message translates to:
  /// **'목표 범위를 확인해 주세요. 하한이 상한보다 작아야 해요.'**
  String get planErrRange;

  /// No description provided for @planErrHypo.
  ///
  /// In ko, this message translates to:
  /// **'저혈당 기준은 40–150 사이로 입력해 주세요.'**
  String get planErrHypo;

  /// No description provided for @planErrSave.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 다시 시도해 주세요.'**
  String get planErrSave;

  /// No description provided for @planDosingTimes.
  ///
  /// In ko, this message translates to:
  /// **'투여 시각'**
  String get planDosingTimes;

  /// No description provided for @planAddTime.
  ///
  /// In ko, this message translates to:
  /// **'시각 추가'**
  String get planAddTime;

  /// No description provided for @planTwiceDaily.
  ///
  /// In ko, this message translates to:
  /// **'07:00 · 19:00 (하루 2회)'**
  String get planTwiceDaily;

  /// No description provided for @planInsulinType.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get planInsulinType;

  /// No description provided for @planInsulinName.
  ///
  /// In ko, this message translates to:
  /// **'인슐린 이름'**
  String get planInsulinName;

  /// No description provided for @planDosePerShot.
  ///
  /// In ko, this message translates to:
  /// **'1회 용량'**
  String get planDosePerShot;

  /// No description provided for @planConcentration.
  ///
  /// In ko, this message translates to:
  /// **'인슐린 농도'**
  String get planConcentration;

  /// No description provided for @planMismatch.
  ///
  /// In ko, this message translates to:
  /// **'인슐린({insulin})과 주사기({syringe}) 눈금이 달라요. 눈금대로 넣으면 실제 용량이 크게 달라집니다.'**
  String planMismatch(String insulin, String syringe);

  /// No description provided for @planLower.
  ///
  /// In ko, this message translates to:
  /// **'하한'**
  String get planLower;

  /// No description provided for @planUpper.
  ///
  /// In ko, this message translates to:
  /// **'상한'**
  String get planUpper;

  /// No description provided for @planHypoThreshold.
  ///
  /// In ko, this message translates to:
  /// **'저혈당 기준'**
  String get planHypoThreshold;

  /// No description provided for @planTargetHint.
  ///
  /// In ko, this message translates to:
  /// **'수의사가 정해 준 범위를 넣어 주세요. 기본값은 강아지 100–250, 고양이 100–300입니다.'**
  String get planTargetHint;

  /// No description provided for @planMeterFoodVet.
  ///
  /// In ko, this message translates to:
  /// **'측정기 · 사료 · 병원'**
  String get planMeterFoodVet;

  /// No description provided for @planMeterHint.
  ///
  /// In ko, this message translates to:
  /// **'혈당 측정기 (예: 알파트랙 3)'**
  String get planMeterHint;

  /// No description provided for @planDefaultWet.
  ///
  /// In ko, this message translates to:
  /// **'기본 습식 사료'**
  String get planDefaultWet;

  /// No description provided for @planDefaultDry.
  ///
  /// In ko, this message translates to:
  /// **'기본 건식 사료'**
  String get planDefaultDry;

  /// No description provided for @planVetClinic.
  ///
  /// In ko, this message translates to:
  /// **'다니는 병원'**
  String get planVetClinic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
