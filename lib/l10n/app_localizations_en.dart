// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mettie';

  @override
  String get commonSave => 'Save';

  @override
  String commonSaveCount(int count) {
    return 'Save $count';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonUnset => 'Not set';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonMe => 'Me';

  @override
  String get commonFamily => 'Family';

  @override
  String get commonNetworkError =>
      'Couldn\'t save. Check your connection and try again.';

  @override
  String get commonLoadError => 'Couldn\'t load your data.';

  @override
  String get navHome => 'Home';

  @override
  String get navTrends => 'Trends';

  @override
  String get navCoach => 'AI Coach';

  @override
  String get navBook => 'Health Book';

  @override
  String get navAddRecord => 'Add record';

  @override
  String get needPetFirstForRecord => 'Add a pet first to start recording.';

  @override
  String get switchPet => 'Switch pet';

  @override
  String get unitMgdl => 'mg/dL';

  @override
  String get unitIu => 'IU';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get speciesDog => 'Dog';

  @override
  String get speciesCat => 'Cat';

  @override
  String get glucoseHypo => 'Hypo';

  @override
  String get glucoseLow => 'Low';

  @override
  String get glucoseInRange => 'In range';

  @override
  String get glucoseHigh => 'High';

  @override
  String get glucoseVeryHigh => 'Very high';

  @override
  String get glucoseTypePreMeal => 'Before meal';

  @override
  String get glucoseTypePostMeal => 'After meal';

  @override
  String get glucoseTypeFasting => 'Fasting';

  @override
  String get glucoseTypeNadir => 'Nadir';

  @override
  String get glucoseTypeSpot => 'Spot';

  @override
  String get foodWet => 'Wet';

  @override
  String get foodDry => 'Dry';

  @override
  String get foodRaw => 'Raw';

  @override
  String get foodMixed => 'Mixed';

  @override
  String get foodGeneric => 'Food';

  @override
  String get appetiteGood => 'Ate well';

  @override
  String get appetitePartial => 'Left some';

  @override
  String get appetiteNone => 'Didn\'t eat';

  @override
  String get appetitePoor => 'Poor appetite';

  @override
  String get injectionGiven => 'Given';

  @override
  String get injectionPartial => 'Partial';

  @override
  String get injectionSkipped => 'Skipped';

  @override
  String get obsDrinkMore => 'Drinking more';

  @override
  String get obsDrinkLess => 'Drinking less';

  @override
  String get obsUrinateMore => 'Urinating more';

  @override
  String get obsUrinateLess => 'Urinating less';

  @override
  String get obsNoAppetite => 'No appetite';

  @override
  String get obsVomit => 'Vomiting';

  @override
  String obsVomitCount(int count) {
    return 'Vomited $count×';
  }

  @override
  String get obsDiarrhea => 'Diarrhea';

  @override
  String get obsConstipation => 'Constipation';

  @override
  String get obsLethargy => 'Lethargic';

  @override
  String get obsWalkMore => 'Walked more than usual';

  @override
  String get obsWalkLess => 'Walked less than usual';

  @override
  String get obsEyeCloudy => 'Cloudy eyes / vision issues';

  @override
  String get obsLitterLarge => 'Large litter clumps';

  @override
  String get obsHindGait => 'Abnormal hind-leg gait';

  @override
  String get writerSubjectMe => 'You';

  @override
  String writerSubjectOther(String name) {
    return '$name';
  }

  @override
  String tlInsulin(String dose) {
    return 'Insulin $dose IU';
  }

  @override
  String tlInsulinPartial(String dose) {
    return 'Insulin partial $dose IU';
  }

  @override
  String get tlInsulinSkipped => 'Insulin skipped';

  @override
  String tlGlucose(int value) {
    return 'Glucose $value';
  }

  @override
  String tlFoodAmount(String grams) {
    return 'Food $grams g';
  }

  @override
  String tlWeight(String kg) {
    return 'Weight $kg kg';
  }

  @override
  String get tlEmptyFiltered => 'No records match this filter.';

  @override
  String get tlToday => 'Today';

  @override
  String tlHypoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hypos',
      one: '1 hypo',
    );
    return '$_temp0';
  }

  @override
  String tlDoses(int given, int planned) {
    return 'Doses $given/$planned';
  }

  @override
  String tlSkippedCount(int count) {
    return '$count skipped';
  }

  @override
  String tlGlucoseSingle(int value) {
    return 'Glucose $value';
  }

  @override
  String tlGlucoseAverage(int value) {
    return 'Avg glucose $value';
  }

  @override
  String todayDiagnosisDay(int days) {
    return 'Day $days since diagnosis';
  }

  @override
  String get remainingSoon => 'Soon';

  @override
  String remainingMinutes(int m) {
    return 'in $m min';
  }

  @override
  String remainingHours(int h) {
    return 'in $h h';
  }

  @override
  String remainingHoursMinutes(int h, int m) {
    return 'in $h h $m min';
  }

  @override
  String get slotMorning => 'Morning';

  @override
  String get slotMidday => 'Midday';

  @override
  String get slotEvening => 'Evening';

  @override
  String hypoCardTitle(int value, String time) {
    return 'Hypo $value · $time';
  }

  @override
  String get hypoCardSteps =>
      '1. If weak or trembling, rub honey or syrup on the gums.\n2. Recheck in 15 minutes. Go to a vet right away if there are seizures or reduced consciousness.\n3. Don\'t give the next insulin dose until you\'ve talked with your vet.';

  @override
  String hypoCardVet(String name) {
    return 'Vet: $name';
  }

  @override
  String get setupPlanTitle => 'Set your dosing times';

  @override
  String get setupPlanBody =>
      'We\'ll show the time until the next dose and who in the family has dosed, and help prevent a double dose in the same slot.';

  @override
  String get setupPlanButton => 'Set up care plan';

  @override
  String get doseDueNow => 'Dose due now';

  @override
  String get doseNext => 'Next dose';

  @override
  String doseSlotLabel(String slot) {
    return '$slot dose';
  }

  @override
  String get doseNoneToday => 'No doses recorded today yet';

  @override
  String doseMissedSlot(String slot, String time) {
    return 'No record for the $slot $time dose';
  }

  @override
  String get doseRecordButton => 'Record dose';

  @override
  String doseGivenBy(String slot, String who, String time, String dose) {
    return '$slot: $who gave $dose IU at $time';
  }

  @override
  String latestGlucoseLabel(String time) {
    return 'Latest glucose · $time';
  }

  @override
  String glucoseVsYesterday(String delta) {
    return '$delta vs. this time yesterday';
  }

  @override
  String get last48h => 'Last 48 hours';

  @override
  String otherPetNextDose(String time, String remaining) {
    return 'Next dose $time · $remaining';
  }

  @override
  String get todayRecords => 'Today';

  @override
  String todayGlucoseCount(int count) {
    return 'Glucose ×$count';
  }

  @override
  String get todayEmpty => 'Nothing recorded today yet';

  @override
  String get viewPastRecords => 'See past records';

  @override
  String get weightLabel => 'Weight';

  @override
  String weightMeasuredOn(String date) {
    return 'Measured $date';
  }

  @override
  String weightChangeSince(String date, String pct) {
    return '$pct since $date';
  }

  @override
  String get noPetTitle => 'No pets yet';

  @override
  String get noPetBody =>
      'Dogs and cats are both welcome.\nAdd your pet from the Health Book.';

  @override
  String get noPetButton => 'Add a pet';

  @override
  String get kindAll => 'All';

  @override
  String get kindGlucose => 'Glucose';

  @override
  String get kindInsulin => 'Insulin';

  @override
  String get kindMeal => 'Meal';

  @override
  String get kindWeight => 'Weight';

  @override
  String get kindObservation => 'Observation';

  @override
  String get trendsAddPetFirst => 'Add a pet first.';

  @override
  String trendsSubtitle(String from, String to) {
    return 'Trends · $from – $to';
  }

  @override
  String trendsTarget(int min, int max) {
    return 'Target $min–$max';
  }

  @override
  String get trendsNoGlucose => 'No glucose readings in this period';

  @override
  String get trendsRecords => 'Records';

  @override
  String periodDays(int days) {
    return '${days}d';
  }

  @override
  String get legendTarget => 'Target range';

  @override
  String get legendReading => 'Reading';

  @override
  String get legendHypo => 'Hypo';

  @override
  String get legendDose => 'Dose';

  @override
  String get legendSkipped => 'Skipped';

  @override
  String get tirTitle => 'Time in range';

  @override
  String tirReadings(int count) {
    return '$count readings';
  }

  @override
  String get summaryTitle => 'Summary';

  @override
  String summaryComparedTo(int days) {
    return 'vs. previous $days days';
  }

  @override
  String get summaryAverage => 'Average';

  @override
  String get summaryLowest => 'Lowest';

  @override
  String get summaryHighest => 'Highest';

  @override
  String weightTrendTrailing(String kg, String date, String pct) {
    return '$kg kg · $pct since $date';
  }

  @override
  String get entryNothingToSave => 'Enter something to save.';

  @override
  String entryTitle(String name) {
    return 'New record for $name';
  }

  @override
  String get entryChangeTime => 'Change time';

  @override
  String get entryGlucoseField => 'Glucose';

  @override
  String get entryInsulinUnset => 'Insulin not set';

  @override
  String entryInsulinConcentration(String value) {
    return 'Insulin $value';
  }

  @override
  String entrySyringe(String value) {
    return '$value syringe';
  }

  @override
  String get entryPen => 'Pen';

  @override
  String get entryMismatchTitle => 'Insulin and syringe don\'t match';

  @override
  String entryMismatchBody(String insulin, String syringe) {
    return 'The insulin is $insulin but the syringe is set to $syringe. Drawing to the marks would give a very different dose. Check the care plan in the Health Book.';
  }

  @override
  String get entryDoseField => 'Dose';

  @override
  String get entryNotes => 'Notes';

  @override
  String get dupTitle => 'This dose was already given';

  @override
  String dupBody(String who, String time, String dose) {
    return '$who recorded $dose IU at $time. Giving another dose risks hypoglycemia.';
  }

  @override
  String get dupAcknowledge =>
      'I understand. This is a separate dose, record it.';

  @override
  String get insulinCaninsulin => 'Caninsulin (Vetsulin)';

  @override
  String get insulinLantus => 'Lantus';

  @override
  String get insulinLevemir => 'Levemir';

  @override
  String get insulinProZinc => 'ProZinc';

  @override
  String get insulinNph => 'Humulin N / Novolin N (NPH)';

  @override
  String get insulinTresiba => 'Tresiba';

  @override
  String get insulinToujeo => 'Toujeo';

  @override
  String get insulinOther => 'Other';

  @override
  String get bookAddPet => 'Add a pet';

  @override
  String get bookManagePets => 'Manage pets';

  @override
  String get bookAddPetHint => 'Dogs and cats are both welcome';

  @override
  String get bookManagePetsHint => 'Add · Edit · Delete · Invite code';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMaleNeutered => 'Male (neutered)';

  @override
  String get sexFemaleSpayed => 'Female (spayed)';

  @override
  String ageYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years yrs',
      one: '1 yr',
    );
    return '$_temp0';
  }

  @override
  String diagnosedOn(String date) {
    return 'Diagnosed $date';
  }

  @override
  String get planTitle => 'Diabetes care plan';

  @override
  String get planInsulin => 'Insulin';

  @override
  String get planDoseTimes => 'Dose · Times';

  @override
  String get planTimesUnset => 'Dosing times not set';

  @override
  String get planSyringe => 'Syringe';

  @override
  String get planTarget => 'Target glucose';

  @override
  String planTargetValue(int min, int max, int hypo) {
    return '$min – $max · hypo below $hypo';
  }

  @override
  String get planMeter => 'Meter';

  @override
  String get planFood => 'Food';

  @override
  String get planVet => 'Vet';

  @override
  String get conditionTitle => 'Condition care';

  @override
  String conditionBody(String name) {
    return 'If $name has been diagnosed with diabetes, create a care plan to track dosing times and glucose targets, and prevent double doses across the family.';
  }

  @override
  String get conditionStartDiabetes => 'Start diabetes care';

  @override
  String planSheetTitle(String name) {
    return '$name\'s diabetes care plan';
  }

  @override
  String get planErrRange =>
      'Check the target range. The lower limit must be below the upper limit.';

  @override
  String get planErrHypo => 'Enter a hypo threshold between 40 and 150.';

  @override
  String get planErrSave => 'Couldn\'t save. Please try again.';

  @override
  String get planDosingTimes => 'Dosing times';

  @override
  String get planAddTime => 'Add time';

  @override
  String get planTwiceDaily => '07:00 · 19:00 (twice daily)';

  @override
  String get planInsulinType => 'Type';

  @override
  String get planInsulinName => 'Insulin name';

  @override
  String get planDosePerShot => 'Dose per injection';

  @override
  String get planConcentration => 'Concentration';

  @override
  String planMismatch(String insulin, String syringe) {
    return 'The insulin ($insulin) and syringe ($syringe) don\'t match. Drawing to the marks would give a very different dose.';
  }

  @override
  String get planLower => 'Lower';

  @override
  String get planUpper => 'Upper';

  @override
  String get planHypoThreshold => 'Hypo below';

  @override
  String get planTargetHint =>
      'Use the range your vet gave you. Defaults are 100–250 for dogs and 100–300 for cats.';

  @override
  String get planMeterFoodVet => 'Meter · Food · Vet';

  @override
  String get planMeterHint => 'Glucose meter (e.g. AlphaTrak 3)';

  @override
  String get planDefaultWet => 'Usual wet food';

  @override
  String get planDefaultDry => 'Usual dry food';

  @override
  String get planVetClinic => 'Your vet clinic';
}
