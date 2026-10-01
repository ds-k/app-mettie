import 'package:flutter_test/flutter_test.dart';
import 'package:mettie/data/models/pet.dart';
import 'package:mettie/data/models/record.dart';
import 'package:mettie/domain/dosing.dart';
import 'package:mettie/domain/glucose.dart';

Pet _pet({String species = 'cat', int? min, int? max, int hypo = 80}) => Pet(
      id: 'p',
      familyId: 'f',
      name: 'Coco',
      species: species,
      targetGlucoseMin: min,
      targetGlucoseMax: max,
      hypoThreshold: hypo,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Record _rec(DateTime at, {int? glucose, double? dose, String? status, String id = ''}) => Record(
      id: id.isEmpty ? at.toIso8601String() : id,
      petId: 'p',
      writerId: 'u',
      recordedAt: at,
      glucoseValue: glucose,
      insulinDose: dose,
      injectionStatus: status,
      createdAt: at,
    );

void main() {
  group('GlucoseRange', () {
    test('저장값이 없으면 종별 기본 목표 범위를 쓴다', () {
      expect(GlucoseRange.forPet(_pet(species: 'cat')).max, 300);
      expect(GlucoseRange.forPet(_pet(species: 'dog')).max, 250);
    });

    test('경계값을 상태로 분류한다', () {
      final r = GlucoseRange.forPet(_pet(species: 'cat'));
      expect(r.classify(79), GlucoseStatus.hypo);
      expect(r.classify(80), GlucoseStatus.low);
      expect(r.classify(100), GlucoseStatus.inRange);
      expect(r.classify(300), GlucoseStatus.inRange);
      expect(r.classify(301), GlucoseStatus.high);
      expect(r.classify(400), GlucoseStatus.high);
      expect(r.classify(401), GlucoseStatus.veryHigh);
    });

    test('같은 값도 강아지와 고양이에서 다르게 분류된다', () {
      expect(GlucoseRange.forPet(_pet(species: 'dog')).classify(280), GlucoseStatus.high);
      expect(GlucoseRange.forPet(_pet(species: 'cat')).classify(280), GlucoseStatus.inRange);
    });

    test('펫별 저혈당 기준을 따른다', () {
      expect(GlucoseRange.forPet(_pet(hypo: 70)).classify(75), GlucoseStatus.low);
    });
  });

  test('목표 범위 내 비율을 계산한다', () {
    final d = GlucoseDistribution.of([72, 150, 200, 350], GlucoseRange.forPet(_pet()));
    expect(d.timeInRange, 0.5);
    expect(d.ratio(GlucoseStatus.hypo), 0.25);
  });

  test('기간 요약은 직전 같은 길이 기간과 비교한다', () {
    final to = DateTime(2026, 10, 1, 12);
    final from = to.subtract(const Duration(days: 7));
    final records = [
      _rec(DateTime(2026, 9, 20), glucose: 300),
      _rec(DateTime(2026, 9, 22), glucose: 280),
      _rec(DateTime(2026, 9, 25), glucose: 220),
      _rec(DateTime(2026, 9, 27), glucose: 72),
      _rec(DateTime(2026, 9, 30), glucose: 230),
    ];
    final s = GlucosePeriodSummary.of(records, from, to);
    expect(s.count, 3);
    expect(s.lowest!.glucoseValue, 72);
    expect(s.highest!.glucoseValue, 230);
    expect(s.previousAverage, 290);
    expect(s.averageDelta, closeTo(174 - 290, 0.01));
  });

  group('투여 일정', () {
    const times = ['07:00', '19:00'];

    test('같은 회차(3시간 안)의 투여 완료 기록을 중복으로 찾는다', () {
      final given = _rec(DateTime(2026, 10, 1, 19, 2), dose: 2, status: 'given');
      expect(findConflictingDose([given], DateTime(2026, 10, 1, 19, 30)), same(given));
      expect(findConflictingDose([given], DateTime(2026, 10, 1, 22, 30)), isNull);
    });

    test('생략 기록과 용량 0은 중복으로 보지 않는다', () {
      final skipped = _rec(DateTime(2026, 10, 1, 19), dose: 0, status: 'skipped');
      expect(findConflictingDose([skipped], DateTime(2026, 10, 1, 19, 10)), isNull);
    });

    test('회차 상태를 완료·예정·놓침으로 나눈다', () {
      final now = DateTime(2026, 10, 1, 11);
      final morning = _rec(DateTime(2026, 10, 1, 6, 52), dose: 2, status: 'given');
      final slots = doseSlotsFor(now, times, [morning], now);
      expect(slots.map((s) => s.state), [DoseSlotState.given, DoseSlotState.upcoming]);
      expect(slots.first.record, same(morning));

      final late = doseSlotsFor(now, times, const [], DateTime(2026, 10, 1, 23));
      expect(late.map((s) => s.state), [DoseSlotState.missed, DoseSlotState.missed]);
    });

    test('투여 시각 근처면 투여할 차례로 본다', () {
      final slots = doseSlotsFor(DateTime(2026, 10, 1), times, const [], DateTime(2026, 10, 1, 18, 30));
      expect(slots.last.state, DoseSlotState.due);
    });

    test('다음 투여는 처리되지 않은 가장 가까운 회차이고, 없으면 내일 첫 회차다', () {
      final now = DateTime(2026, 10, 1, 20);
      final evening = _rec(DateTime(2026, 10, 1, 19, 4), dose: 2, status: 'given');
      final next = nextDose(times, [evening], now)!;
      expect(next.scheduledAt, DateTime(2026, 10, 2, 7));
      expect(nextDose(const [], const [], now), isNull);
    });
  });
}
