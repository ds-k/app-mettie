import '../data/models/pet.dart';
import '../data/models/record.dart';

/// 혈당값의 상태. 색과 배지는 이 상태로만 정한다 (값이 범위를 벗어났을 때만 상태 색을 쓴다).
enum GlucoseStatus { hypo, low, inRange, high, veryHigh }

/// 400 초과는 케톤산증 위험 구간이라 종과 관계없이 따로 표시한다.
const int kVeryHighGlucose = 400;

/// 펫의 목표 범위. 저장값이 없으면 종별 기본값(강아지 100–250, 고양이 100–300)을 쓴다.
class GlucoseRange {
  final int hypo;
  final int min;
  final int max;

  const GlucoseRange({required this.hypo, required this.min, required this.max});

  factory GlucoseRange.forPet(Pet pet) {
    final defaultMax = pet.isCat ? 300 : 250;
    return GlucoseRange(
      hypo: pet.hypoThreshold,
      min: pet.targetGlucoseMin ?? 100,
      max: pet.targetGlucoseMax ?? defaultMax,
    );
  }

  GlucoseStatus classify(int value) {
    if (value < hypo) return GlucoseStatus.hypo;
    if (value < min) return GlucoseStatus.low;
    if (value <= max) return GlucoseStatus.inRange;
    if (value <= kVeryHighGlucose) return GlucoseStatus.high;
    return GlucoseStatus.veryHigh;
  }
}

/// 상태별 비율 (목표 범위 내 비율 = TIR).
class GlucoseDistribution {
  final Map<GlucoseStatus, int> counts;
  final int total;

  const GlucoseDistribution(this.counts, this.total);

  factory GlucoseDistribution.of(Iterable<int> values, GlucoseRange range) {
    final counts = {for (final s in GlucoseStatus.values) s: 0};
    var total = 0;
    for (final v in values) {
      counts[range.classify(v)] = counts[range.classify(v)]! + 1;
      total++;
    }
    return GlucoseDistribution(counts, total);
  }

  double ratio(GlucoseStatus status) => total == 0 ? 0 : counts[status]! / total;
  double get timeInRange => ratio(GlucoseStatus.inRange);
}

/// 기간 요약과 직전 같은 길이 기간 대비 변화.
class GlucosePeriodSummary {
  final int count;
  final double? average;
  final Record? lowest;
  final Record? highest;
  final double? previousAverage;

  const GlucosePeriodSummary({
    required this.count,
    this.average,
    this.lowest,
    this.highest,
    this.previousAverage,
  });

  double? get averageDelta =>
      average != null && previousAverage != null ? average! - previousAverage! : null;

  /// [from]~[to] 구간과, 그 직전 같은 길이 구간을 비교한다.
  factory GlucosePeriodSummary.of(Iterable<Record> records, DateTime from, DateTime to) {
    final length = to.difference(from);
    final prevFrom = from.subtract(length);
    final current = <Record>[];
    final previous = <int>[];
    for (final r in records) {
      final v = r.glucoseValue;
      if (v == null) continue;
      if (!r.recordedAt.isBefore(from) && !r.recordedAt.isAfter(to)) {
        current.add(r);
      } else if (!r.recordedAt.isBefore(prevFrom) && r.recordedAt.isBefore(from)) {
        previous.add(v);
      }
    }
    if (current.isEmpty) {
      return GlucosePeriodSummary(
        count: 0,
        previousAverage: previous.isEmpty ? null : previous.reduce((a, b) => a + b) / previous.length,
      );
    }
    Record lowest = current.first, highest = current.first;
    var sum = 0;
    for (final r in current) {
      sum += r.glucoseValue!;
      if (r.glucoseValue! < lowest.glucoseValue!) lowest = r;
      if (r.glucoseValue! > highest.glucoseValue!) highest = r;
    }
    return GlucosePeriodSummary(
      count: current.length,
      average: sum / current.length,
      lowest: lowest,
      highest: highest,
      previousAverage: previous.isEmpty ? null : previous.reduce((a, b) => a + b) / previous.length,
    );
  }
}
