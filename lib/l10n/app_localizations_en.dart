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

  @override
  String get errUnknown =>
      'Something went wrong. Please try again in a moment.';

  @override
  String get errGoogleToken =>
      'Couldn\'t get a Google ID token. Please try again.';

  @override
  String get errGoogleSignIn => 'Google sign-in failed. Please try again.';

  @override
  String get errAppleToken => 'Couldn\'t get an Apple ID token.';

  @override
  String get errAppleSignIn => 'Apple sign-in failed. Please try again.';

  @override
  String get errNotSignedIn => 'Please sign in.';

  @override
  String get errDeleteAccount =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get errInviteCreate =>
      'Couldn\'t create an invite code. Check your connection.';

  @override
  String get errInviteInvalid => 'That invite code isn\'t valid.';

  @override
  String get errInviteExpired => 'That invite code has expired.';

  @override
  String get errInviteAlreadyJoined => 'You\'re already in this family.';

  @override
  String get errJoinFailed =>
      'Couldn\'t join the family. Check your connection.';

  @override
  String get errRecordNotFound =>
      'The record wasn\'t found, or you don\'t have permission to delete it.';

  @override
  String get errSaveFailed => 'Couldn\'t save.';

  @override
  String get petDeleteTitle => 'Delete pet';

  @override
  String get petLeaveTitle => 'Leave family';

  @override
  String petDeleteBody(String name) {
    return 'Delete all of $name\'s data? This can\'t be undone.';
  }

  @override
  String petLeaveBody(String name) {
    return 'Leave $name\'s family space?';
  }

  @override
  String get petDeleted => 'Deleted.';

  @override
  String get petLeft => 'You left the family.';

  @override
  String get petLeave => 'Leave';

  @override
  String get petManageTitle => 'Manage pets';

  @override
  String get petAddTooltip => 'Add a pet';

  @override
  String get petNewTitle => 'Add a new pet';

  @override
  String get petBasicInfo => 'Basics';

  @override
  String get petName => 'Name';

  @override
  String get petNameRequired => 'Enter a name';

  @override
  String get petSpecies => 'Species';

  @override
  String get petSex => 'Sex';

  @override
  String get petBreedOptional => 'Breed (optional)';

  @override
  String get petNeutered => 'Spayed / neutered';

  @override
  String get petHealthInfo => 'Health & care';

  @override
  String get petWeightKg => 'Weight (kg)';

  @override
  String get petWeightInvalid => 'Enter a valid weight (above 0, up to 150)';

  @override
  String get petInsulinTypeOptional => 'Insulin type (optional)';

  @override
  String get petInsulinOther => 'Enter other insulin';

  @override
  String get petInsulinUnits => 'Units (IU)';

  @override
  String get petInsulinUnitsInvalid => 'Enter valid units (above 0, up to 150)';

  @override
  String get petTargetGlucose => 'Target glucose';

  @override
  String get petSaveAndStart => 'Save and start';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleCoCaregiver => 'Co-caregiver';

  @override
  String get breedUnknown => 'Unknown breed';

  @override
  String get familySharing => 'Family sharing';

  @override
  String get inviteCreate => 'Get invite code';

  @override
  String get inviteCodeTitle => 'Invite code';

  @override
  String get inviteCodeBody =>
      'Copy this code and send it to your family.\nIt\'s valid for 24 hours.';

  @override
  String get inviteCopy => 'Copy';

  @override
  String get inviteCopied => 'Invite code copied.';

  @override
  String get familyJoinTitle => 'Join a family';

  @override
  String get familyJoinPrompt =>
      'Enter the 6-character invite code you received.';

  @override
  String get familyInviteCodeLabel => 'Invite code';

  @override
  String get familyCodeRequired => 'Enter the 6-character code.';

  @override
  String get familyJoined => 'You joined the family.';

  @override
  String get familyJoin => 'Join';

  @override
  String get familyTitle => 'Family (co-caregivers)';

  @override
  String get familyIntro =>
      'Share and manage your pet\'s records with your family in real time.';

  @override
  String get familyInviteTitle => 'Invite family';

  @override
  String familyInviteBody(String name) {
    return 'Invite a partner to $name\'s space. The code is valid for 24 hours.';
  }

  @override
  String get familyGetCode => 'Get an invite code';

  @override
  String get familyJoinBody =>
      'If a family member sent you a 6-character code, tap below to enter it.';

  @override
  String get familyEnterCode => 'Enter invite code';

  @override
  String get settingsAppInfo => 'App info & settings';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get settingsCannotOpenBrowser => 'Couldn\'t open the web browser.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountBody =>
      'Delete your Mettie account?\nAll pet records and personal data will be deleted immediately and can\'t be recovered.';

  @override
  String get settingsDeleteAccountConfirm => 'Delete account';

  @override
  String get accountInfo => 'Account';

  @override
  String get accountDefaultName => 'User';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get rowOther => 'Other';

  @override
  String get rowMorning => 'Morning';

  @override
  String get rowLunch => 'Afternoon';

  @override
  String get rowEvening => 'Evening';

  @override
  String get rowNight => 'Night';

  @override
  String rowPreMeal(String time) {
    return '$time, before meal';
  }

  @override
  String rowPostMeal(String time) {
    return '$time, after meal';
  }

  @override
  String get rowFasting => 'Fasting';

  @override
  String get rowNadir => 'Nadir (lowest glucose)';

  @override
  String rowInsulin(String time) {
    return '$time insulin';
  }

  @override
  String rowMeal(String time) {
    return '$time meal';
  }

  @override
  String get rowDeleteTitle => 'Delete record';

  @override
  String get rowDeleteBody =>
      'Delete this record?\nDeleted records can\'t be recovered.';

  @override
  String get rowDeleted => 'Record deleted.';

  @override
  String get rowFood => 'Food';

  @override
  String get selectorTitle => 'Choose a pet';

  @override
  String get selectorEmpty => 'No pets yet.';

  @override
  String get selectorDeleteAction => 'Delete';

  @override
  String get loginHeadline => 'Your pet\'s glucose log,\nwith a smart AI guide';

  @override
  String get loginSubtitle =>
      'From quick glucose checks to daily notes,\nMettie AI is here to help.';

  @override
  String get loginWithEmail => 'Continue with email';

  @override
  String get loginOr => 'or';

  @override
  String get loginWithApple => 'Continue with Apple';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get emailAgreeRequired =>
      'Please agree to the Terms of Service and Privacy Policy.';

  @override
  String get emailVerifyTitle => 'Verify your email';

  @override
  String get emailLinkSent => 'We sent you a sign-up link.';

  @override
  String emailSentTo(String email) {
    return 'We sent a confirmation link to $email.';
  }

  @override
  String get emailCheckInbox =>
      'Tap the link in the email to finish signing up. (Check your spam folder too.)';

  @override
  String get emailSignUpTitle => 'Sign up with email';

  @override
  String get emailSignInTitle => 'Sign in with email';

  @override
  String get emailNameHint => 'Enter your name';

  @override
  String get emailName => 'Name';

  @override
  String get emailNameRequired => 'Enter your name.';

  @override
  String get emailEmail => 'Email';

  @override
  String get emailEmailRequired => 'Enter your email.';

  @override
  String get emailEmailInvalid => 'That doesn\'t look like a valid email.';

  @override
  String get emailPasswordHint => 'Enter a password (6+ characters)';

  @override
  String get emailPassword => 'Password';

  @override
  String get emailPasswordRequired => 'Enter your password.';

  @override
  String get emailPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String termsAgreement(String terms, String privacy) {
    return 'I agree to Mettie\'s $terms and $privacy.';
  }

  @override
  String get emailSignUpButton => 'Sign up with email';

  @override
  String get emailSignInButton => 'Sign in with email';

  @override
  String get emailHaveAccount => 'Already have an account? Sign in';

  @override
  String get emailNoAccount => 'No account? Sign up';

  @override
  String get updateTitle => 'Please update Mettie';

  @override
  String get updateBody =>
      'This version is no longer supported. Get the latest version from the store to keep your records safe.';

  @override
  String get updateButton => 'Update';

  @override
  String coachQuota(int used, int limit) {
    return '$used/$limit today';
  }

  @override
  String get coachNewChat => 'New chat';

  @override
  String coachContextBefore(String name) {
    return 'Answers use $name\'s last 14 days of records';
  }

  @override
  String coachContextAfter(String name, int count) {
    return '$name · $count records from the last 14 days';
  }

  @override
  String get coachEmptyTitle => 'Ask anything';

  @override
  String get coachSuggestTrend => 'Is the glucose getting better this week?';

  @override
  String get coachSuggestNadir => 'When should I measure the nadir?';

  @override
  String get coachSuggestVet => 'What should I ask the vet?';

  @override
  String get coachInputHint => 'Message';

  @override
  String get coachSend => 'Send';

  @override
  String get coachStop => 'Stop';

  @override
  String get coachDisclaimer =>
      'Mettie doesn\'t replace your vet. In an emergency, contact a vet right away.';

  @override
  String coachRef(String time) {
    return 'Source · $time';
  }

  @override
  String get coachRefused =>
      'I can\'t answer that one. Try asking another way.';

  @override
  String get coachModelError => 'Couldn\'t get an answer.';

  @override
  String get coachRetry => 'Try again';

  @override
  String coachQuotaExceeded(int limit) {
    return 'You\'ve used all $limit questions for today. You can ask again tomorrow.';
  }

  @override
  String get coachNetworkError => 'Couldn\'t connect. Check your network.';

  @override
  String get coachUnavailable =>
      'AI Coach is unavailable right now. Please try again later.';

  @override
  String get coachNoPet => 'Add a pet to use AI Coach.';

  @override
  String get consentTitle => 'Before you start AI Coach';

  @override
  String get consentBody =>
      'To write answers, AI Coach sends the following to Anthropic\'s AI service (United States).';

  @override
  String get consentItemPet => 'Your pet\'s profile and diabetes care plan';

  @override
  String get consentItemRecords =>
      'Records from the last 14 days (glucose, insulin, meals, weight, observations and notes)';

  @override
  String get consentItemQuestion => 'The questions you type';

  @override
  String get consentFooter =>
      'This information is used only to write answers. You can withdraw consent anytime in Settings.';

  @override
  String get consentAgree => 'Agree and start';

  @override
  String get consentPrivacy => 'View Privacy Policy';

  @override
  String get settingsAiConsent => 'AI Coach data sharing';

  @override
  String get settingsAiConsentOn => 'On';

  @override
  String get settingsAiConsentOff => 'Off';

  @override
  String get settingsAiConsentWithdraw => 'Withdraw consent';

  @override
  String get settingsAiConsentWithdrawBody =>
      'AI Coach will stop working. To use it again, agree from the AI Coach screen.';
}
