import '../data/models/record.dart';

/// 타임라인 한 줄의 종류. 필터 칩과 점 색이 이 값을 따른다.
enum EntryKind { glucose, insulin, meal, weight, observation }

/// 같은 끼니로 묶는 시간 창 (습식·건식을 따로 저장해도 한 줄로 보인다).
const Duration kMealMergeWindow = Duration(minutes: 15);

/// 타임라인 한 줄. 끼니처럼 여러 기록을 묶을 수 있다.
class TimelineEntry {
  final DateTime at;
  final EntryKind kind;
  final List<Record> records;

  const TimelineEntry(this.at, this.kind, this.records);

  Record get primary => records.first;

  /// v1.0에서 한 기록에 여러 항목을 함께 저장한 경우도 있어서, 필터는 포함 여부로 판단한다.
  bool contains(EntryKind k) => records.any((r) => kindsOf(r).contains(k));
}

Set<EntryKind> kindsOf(Record r) => {
      if (r.injectionStatus != null || r.insulinDose != null) EntryKind.insulin,
      if (r.glucoseValue != null) EntryKind.glucose,
      if (r.foodAmountG != null || (r.foodBrand?.isNotEmpty ?? false)) EntryKind.meal,
      if (r.weightKg != null) EntryKind.weight,
      if (_hasObservation(r)) EntryKind.observation,
    };

bool _hasObservation(Record r) =>
    r.waterIntake != null ||
    r.urination != null ||
    r.stoolStatus != null ||
    r.vomitCount > 0 ||
    (r.symptomTags?.isNotEmpty ?? false) ||
    (r.notes?.isNotEmpty ?? false);

EntryKind _primaryKind(Record r) {
  final kinds = kindsOf(r);
  for (final k in [EntryKind.insulin, EntryKind.glucose, EntryKind.meal, EntryKind.weight]) {
    if (kinds.contains(k)) return k;
  }
  return EntryKind.observation;
}

bool _isFoodOnly(Record r) => kindsOf(r).difference({EntryKind.meal, EntryKind.observation}).isEmpty &&
    kindsOf(r).contains(EntryKind.meal);

/// 기록을 최신순 타임라인으로 만든다. 같은 작성자의 사료 기록은 15분 안이면 한 끼로 묶는다.
List<TimelineEntry> buildTimeline(Iterable<Record> records) {
  final sorted = [...records]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  final entries = <TimelineEntry>[];
  for (final r in sorted) {
    if (_isFoodOnly(r) && entries.isNotEmpty) {
      final last = entries.last;
      if (last.kind == EntryKind.meal &&
          last.records.every(_isFoodOnly) &&
          last.primary.writerId == r.writerId &&
          last.at.difference(r.recordedAt).abs() <= kMealMergeWindow) {
        last.records.add(r);
        continue;
      }
    }
    entries.add(TimelineEntry(r.recordedAt, _primaryKind(r), [r]));
  }
  return entries;
}

/// 날짜 머리에 붙는 하루 요약.
class DaySummary {
  final int dosesGiven;
  final int dosesSkipped;
  final int dosesPlanned;
  final List<int> glucoseValues;

  const DaySummary({
    required this.dosesGiven,
    required this.dosesSkipped,
    required this.dosesPlanned,
    required this.glucoseValues,
  });

  double? get glucoseAverage =>
      glucoseValues.isEmpty ? null : glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;

  factory DaySummary.of(Iterable<Record> dayRecords, {int dosesPlanned = 0}) {
    var given = 0, skipped = 0;
    final glucose = <int>[];
    for (final r in dayRecords) {
      if (r.injectionStatus == 'given' && (r.insulinDose ?? 0) > 0) given++;
      if (r.injectionStatus == 'skipped') skipped++;
      if (r.glucoseValue != null) glucose.add(r.glucoseValue!);
    }
    return DaySummary(
      dosesGiven: given,
      dosesSkipped: skipped,
      dosesPlanned: dosesPlanned,
      glucoseValues: glucose,
    );
  }
}
