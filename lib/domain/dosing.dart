import '../data/models/record.dart';

/// 같은 회차로 보는 시간 창. 서버 트리거 guard_duplicate_dose와 같은 값이어야 한다.
const Duration kDoseWindow = Duration(hours: 3);

enum DoseSlotState { given, skipped, due, upcoming, missed }

/// 하루 투여 일정 중 한 회차와 그 회차를 처리한 기록.
class DoseSlot {
  final DateTime scheduledAt;
  final DoseSlotState state;
  final Record? record;

  const DoseSlot({required this.scheduledAt, required this.state, this.record});
}

bool _isGivenDose(Record r) =>
    r.injectionStatus == 'given' && (r.insulinDose ?? 0) > 0;

/// [at] 기준 같은 회차(±3시간)에 이미 투여 완료 기록이 있으면 그 기록을 돌려준다.
Record? findConflictingDose(
  Iterable<Record> records,
  DateTime at, {
  String? excludeId,
}) {
  Record? closest;
  for (final r in records) {
    if (!_isGivenDose(r) || r.id == excludeId) continue;
    final gap = r.recordedAt.difference(at).abs();
    if (gap > kDoseWindow) continue;
    if (closest == null || gap < closest.recordedAt.difference(at).abs()) {
      closest = r;
    }
  }
  return closest;
}

/// 'HH:mm' 투여 시각 목록과 기록으로 [day]의 회차 상태를 만든다.
List<DoseSlot> doseSlotsFor(
  DateTime day,
  List<String> dosingTimes,
  Iterable<Record> records,
  DateTime now,
) {
  final slots = <DoseSlot>[];
  final times = [...dosingTimes]..sort();
  for (final t in times) {
    final parts = t.split(':');
    final scheduled = DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    Record? match;
    for (final r in records) {
      if (r.injectionStatus == null) continue;
      if (r.recordedAt.difference(scheduled).abs() > kDoseWindow) continue;
      // 투여 완료 기록을 생략 기록보다 우선한다
      if (match == null || (_isGivenDose(r) && !_isGivenDose(match))) match = r;
    }

    final DoseSlotState state;
    if (match != null) {
      state = _isGivenDose(match) ? DoseSlotState.given : DoseSlotState.skipped;
    } else if (now.isBefore(scheduled.subtract(kDoseWindow))) {
      state = DoseSlotState.upcoming;
    } else if (now.isAfter(scheduled.add(kDoseWindow))) {
      state = DoseSlotState.missed;
    } else {
      state = DoseSlotState.due;
    }
    slots.add(DoseSlot(scheduledAt: scheduled, state: state, record: match));
  }
  return slots;
}

/// 아직 처리되지 않은 가장 가까운 회차. 오늘 남은 회차가 없으면 내일 첫 회차.
DoseSlot? nextDose(
  List<String> dosingTimes,
  Iterable<Record> records,
  DateTime now,
) {
  if (dosingTimes.isEmpty) return null;
  final today = doseSlotsFor(now, dosingTimes, records, now);
  for (final s in today) {
    if (s.state == DoseSlotState.due || s.state == DoseSlotState.upcoming) {
      return s;
    }
  }
  final tomorrow = now.add(const Duration(days: 1));
  return doseSlotsFor(tomorrow, dosingTimes, records, now).first;
}
