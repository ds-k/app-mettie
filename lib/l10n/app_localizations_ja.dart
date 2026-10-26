// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'メッティ';

  @override
  String get commonSave => '保存';

  @override
  String commonSaveCount(int count) {
    return '$count件を保存';
  }

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonEdit => '編集';

  @override
  String get commonDelete => '削除';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonSettings => '設定';

  @override
  String get commonUnset => '未設定';

  @override
  String get commonAdd => '追加';

  @override
  String get commonMe => '自分';

  @override
  String get commonFamily => '家族';

  @override
  String get commonNetworkError => '保存できませんでした。通信状況を確認して、もう一度お試しください。';

  @override
  String get commonLoadError => 'データを読み込めませんでした。';

  @override
  String get navHome => 'ホーム';

  @override
  String get navTrends => '推移';

  @override
  String get navCoach => 'AIコーチ';

  @override
  String get navBook => '健康手帳';

  @override
  String get navAddRecord => '記録を追加';

  @override
  String get needPetFirstForRecord => '記録するには、まずペットを登録してください。';

  @override
  String get switchPet => 'ペットを切り替え';

  @override
  String get unitMgdl => 'mg/dL';

  @override
  String get unitIu => 'IU';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get speciesDog => '犬';

  @override
  String get speciesCat => '猫';

  @override
  String get glucoseHypo => '低血糖';

  @override
  String get glucoseLow => '低め';

  @override
  String get glucoseInRange => '目標範囲';

  @override
  String get glucoseHigh => '高め';

  @override
  String get glucoseVeryHigh => '非常に高い';

  @override
  String get glucoseTypePreMeal => '食前';

  @override
  String get glucoseTypePostMeal => '食後';

  @override
  String get glucoseTypeFasting => '空腹時';

  @override
  String get glucoseTypeNadir => 'ナディア';

  @override
  String get glucoseTypeSpot => '随時';

  @override
  String get foodWet => 'ウェット';

  @override
  String get foodDry => 'ドライ';

  @override
  String get foodRaw => '生食';

  @override
  String get foodMixed => '混合';

  @override
  String get foodGeneric => 'フード';

  @override
  String get appetiteGood => 'よく食べた';

  @override
  String get appetitePartial => '少し残した';

  @override
  String get appetiteNone => '食べなかった';

  @override
  String get appetitePoor => '食欲低下';

  @override
  String get injectionGiven => '投与済み';

  @override
  String get injectionPartial => '一部投与';

  @override
  String get injectionSkipped => 'スキップ';

  @override
  String get obsDrinkMore => '飲水量が多い';

  @override
  String get obsDrinkLess => '飲水量が少ない';

  @override
  String get obsUrinateMore => '尿が多い';

  @override
  String get obsUrinateLess => '尿が少ない';

  @override
  String get obsNoAppetite => '食欲なし';

  @override
  String get obsVomit => '嘔吐';

  @override
  String obsVomitCount(int count) {
    return '嘔吐$count回';
  }

  @override
  String get obsDiarrhea => '下痢';

  @override
  String get obsConstipation => '便秘';

  @override
  String get obsLethargy => '元気がない';

  @override
  String get obsWalkMore => '散歩がいつもより多い';

  @override
  String get obsWalkLess => '散歩がいつもより少ない';

  @override
  String get obsEyeCloudy => '目の濁り・視覚の異常';

  @override
  String get obsLitterLarge => 'トイレの固まりが大きい';

  @override
  String get obsHindGait => '後ろ足の歩き方の異常';

  @override
  String get writerSubjectMe => '自分が';

  @override
  String writerSubjectOther(String name) {
    return '$nameが';
  }

  @override
  String tlInsulin(String dose) {
    return 'インスリン $dose IU';
  }

  @override
  String tlInsulinPartial(String dose) {
    return 'インスリン一部 $dose IU';
  }

  @override
  String get tlInsulinSkipped => 'インスリンをスキップ';

  @override
  String tlGlucose(int value) {
    return '血糖値 $value';
  }

  @override
  String tlFoodAmount(String grams) {
    return 'フード $grams g';
  }

  @override
  String tlWeight(String kg) {
    return '体重 $kg kg';
  }

  @override
  String get tlEmptyFiltered => 'この条件の記録はありません。';

  @override
  String get tlToday => '今日';

  @override
  String tlHypoCount(int count) {
    return '低血糖 $count回';
  }

  @override
  String tlDoses(int given, int planned) {
    return '投与 $given/$planned';
  }

  @override
  String tlSkippedCount(int count) {
    return 'スキップ $count';
  }

  @override
  String tlGlucoseSingle(int value) {
    return '血糖値 $value';
  }

  @override
  String tlGlucoseAverage(int value) {
    return '血糖値平均 $value';
  }

  @override
  String todayDiagnosisDay(int days) {
    return '診断から$days日目';
  }

  @override
  String get remainingSoon => 'まもなく';

  @override
  String remainingMinutes(int m) {
    return '$m分後';
  }

  @override
  String remainingHours(int h) {
    return '$h時間後';
  }

  @override
  String remainingHoursMinutes(int h, int m) {
    return '$h時間$m分後';
  }

  @override
  String get slotMorning => '朝';

  @override
  String get slotMidday => '昼';

  @override
  String get slotEvening => '夜';

  @override
  String hypoCardTitle(int value, String time) {
    return '低血糖 $value・$time';
  }

  @override
  String get hypoCardSteps =>
      '1. ぐったりしたり震えたりしていたら、はちみつやシロップを歯ぐきに塗ってください。\n2. 15分後にもう一度測り、けいれんや意識の低下があればすぐに動物病院へ。\n3. 獣医師に相談するまで、次のインスリンは投与しないでください。';

  @override
  String hypoCardVet(String name) {
    return '病院：$name';
  }

  @override
  String get setupPlanTitle => '投与時間を設定してください';

  @override
  String get setupPlanBody =>
      '設定すると、次の投与までの時間と家族の投与状況を表示し、同じ回に二重投与しないようお知らせします。';

  @override
  String get setupPlanButton => '管理計画を設定';

  @override
  String get doseDueNow => '今が投与の時間';

  @override
  String get doseNext => '次の投与';

  @override
  String doseSlotLabel(String slot) {
    return '$slotの回';
  }

  @override
  String get doseNoneToday => '今日はまだ投与記録がありません';

  @override
  String doseMissedSlot(String slot, String time) {
    return '$slot $timeの回の記録がありません';
  }

  @override
  String get doseRecordButton => '投与を記録';

  @override
  String doseGivenBy(String slot, String who, String time, String dose) {
    return '$slot：$who$timeに$dose IUを投与済み';
  }

  @override
  String latestGlucoseLabel(String time) {
    return '最新の血糖値・$time';
  }

  @override
  String glucoseVsYesterday(String delta) {
    return '昨日の同じ頃より$delta';
  }

  @override
  String get last48h => '直近48時間';

  @override
  String otherPetNextDose(String time, String remaining) {
    return '次の投与 $time・$remaining';
  }

  @override
  String get todayRecords => '今日の記録';

  @override
  String todayGlucoseCount(int count) {
    return '血糖値 $count回';
  }

  @override
  String get todayEmpty => '今日はまだ記録がありません';

  @override
  String get viewPastRecords => '過去の記録を見る';

  @override
  String get weightLabel => '体重';

  @override
  String weightMeasuredOn(String date) {
    return '$dateに測定';
  }

  @override
  String weightChangeSince(String date, String pct) {
    return '$date比 $pct';
  }

  @override
  String get noPetTitle => 'まだペットが登録されていません';

  @override
  String get noPetBody => '犬も猫も登録できます。\n健康手帳からペットを登録してください。';

  @override
  String get noPetButton => 'ペットを登録';

  @override
  String get kindAll => 'すべて';

  @override
  String get kindGlucose => '血糖値';

  @override
  String get kindInsulin => 'インスリン';

  @override
  String get kindMeal => '食事';

  @override
  String get kindWeight => '体重';

  @override
  String get kindObservation => '観察';

  @override
  String get trendsAddPetFirst => 'まずペットを登録してください。';

  @override
  String trendsSubtitle(String from, String to) {
    return '推移・$from〜$to';
  }

  @override
  String trendsTarget(int min, int max) {
    return '目標 $min〜$max';
  }

  @override
  String get trendsNoGlucose => 'この期間の血糖値の記録はありません';

  @override
  String get trendsRecords => '記録';

  @override
  String periodDays(int days) {
    return '$days日';
  }

  @override
  String get legendTarget => '目標範囲';

  @override
  String get legendReading => '測定値';

  @override
  String get legendHypo => '低血糖';

  @override
  String get legendDose => '投与';

  @override
  String get legendSkipped => 'スキップ';

  @override
  String get tirTitle => '目標範囲内の割合';

  @override
  String tirReadings(int count) {
    return '測定 $count回';
  }

  @override
  String get summaryTitle => 'まとめ';

  @override
  String summaryComparedTo(int days) {
    return '直前$days日と比較';
  }

  @override
  String get summaryAverage => '平均';

  @override
  String get summaryLowest => '最低';

  @override
  String get summaryHighest => '最高';

  @override
  String weightTrendTrailing(String kg, String date, String pct) {
    return '$kg kg・$date比 $pct';
  }

  @override
  String get entryNothingToSave => '保存する内容を入力してください。';

  @override
  String entryTitle(String name) {
    return '$nameの記録を追加';
  }

  @override
  String get entryChangeTime => '時刻を変更';

  @override
  String get entryGlucoseField => '血糖値';

  @override
  String get entryInsulinUnset => 'インスリン未設定';

  @override
  String entryInsulinConcentration(String value) {
    return 'インスリン $value';
  }

  @override
  String entrySyringe(String value) {
    return '$valueシリンジ';
  }

  @override
  String get entryPen => 'ペン';

  @override
  String get entryMismatchTitle => 'インスリンとシリンジの目盛りが違います';

  @override
  String entryMismatchBody(String insulin, String syringe) {
    return 'インスリンは$insulinですが、シリンジは$syringeに設定されています。目盛りどおりに入れると実際の量が大きく変わります。健康手帳の管理計画を確認してください。';
  }

  @override
  String get entryDoseField => '投与量';

  @override
  String get entryNotes => 'メモ';

  @override
  String get dupTitle => 'この回はすでに投与されています';

  @override
  String dupBody(String who, String time, String dose) {
    return '$who$timeに$dose IUの投与を記録しています。もう一度投与すると低血糖の危険があります。';
  }

  @override
  String get dupAcknowledge => '確認しました。別の投与なので記録します。';

  @override
  String get insulinCaninsulin => 'カニンシュリン';

  @override
  String get insulinLantus => 'ランタス';

  @override
  String get insulinLevemir => 'レベミル';

  @override
  String get insulinProZinc => 'プロジンク';

  @override
  String get insulinNph => 'ヒューマリンN／ノボリンN';

  @override
  String get insulinTresiba => 'トレシーバ';

  @override
  String get insulinToujeo => 'ランタスXR';

  @override
  String get insulinOther => 'その他';

  @override
  String get bookAddPet => 'ペットを登録';

  @override
  String get bookManagePets => 'ペットの管理';

  @override
  String get bookAddPetHint => '犬も猫も登録できます';

  @override
  String get bookManagePetsHint => '登録・編集・削除・招待コード';

  @override
  String get sexMale => 'オス';

  @override
  String get sexFemale => 'メス';

  @override
  String get sexMaleNeutered => 'オス（去勢済み）';

  @override
  String get sexFemaleSpayed => 'メス（避妊済み）';

  @override
  String ageYears(int years) {
    return '$years歳';
  }

  @override
  String diagnosedOn(String date) {
    return '$date 診断';
  }

  @override
  String get planTitle => '糖尿病の管理計画';

  @override
  String get planInsulin => 'インスリン';

  @override
  String get planDoseTimes => '量・時刻';

  @override
  String get planTimesUnset => '投与時刻未設定';

  @override
  String get planSyringe => 'シリンジ';

  @override
  String get planTarget => '目標血糖値';

  @override
  String planTargetValue(int min, int max, int hypo) {
    return '$min〜$max・低血糖 $hypo未満';
  }

  @override
  String get planMeter => '血糖測定器';

  @override
  String get planFood => 'フード';

  @override
  String get planVet => '病院';

  @override
  String get conditionTitle => '疾患の管理';

  @override
  String conditionBody(String name) {
    return '$nameが糖尿病と診断されたら、管理計画を作って投与時間や血糖値の目標を設定し、家族間の二重投与を防げます。';
  }

  @override
  String get conditionStartDiabetes => '糖尿病の管理を始める';

  @override
  String planSheetTitle(String name) {
    return '$nameの糖尿病管理計画';
  }

  @override
  String get planErrRange => '目標範囲を確認してください。下限は上限より小さくしてください。';

  @override
  String get planErrHypo => '低血糖の基準は40〜150の間で入力してください。';

  @override
  String get planErrSave => '保存できませんでした。もう一度お試しください。';

  @override
  String get planDosingTimes => '投与時刻';

  @override
  String get planAddTime => '時刻を追加';

  @override
  String get planTwiceDaily => '07:00・19:00（1日2回）';

  @override
  String get planInsulinType => '種類';

  @override
  String get planInsulinName => 'インスリン名';

  @override
  String get planDosePerShot => '1回量';

  @override
  String get planConcentration => '濃度';

  @override
  String planMismatch(String insulin, String syringe) {
    return 'インスリン（$insulin）とシリンジ（$syringe）の目盛りが違います。目盛りどおりに入れると実際の量が大きく変わります。';
  }

  @override
  String get planLower => '下限';

  @override
  String get planUpper => '上限';

  @override
  String get planHypoThreshold => '低血糖の基準';

  @override
  String get planTargetHint => '獣医師に指示された範囲を入力してください。初期値は犬100〜250、猫100〜300です。';

  @override
  String get planMeterFoodVet => '測定器・フード・病院';

  @override
  String get planMeterHint => '血糖測定器（例：アルファトラック3）';

  @override
  String get planDefaultWet => 'いつものウェットフード';

  @override
  String get planDefaultDry => 'いつものドライフード';

  @override
  String get planVetClinic => 'かかりつけの病院';
}
