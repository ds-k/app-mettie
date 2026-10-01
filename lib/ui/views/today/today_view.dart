import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/record.dart';
import '../../../domain/dosing.dart';
import '../../../domain/glucose.dart';
import '../../../domain/timeline.dart';
import '../../../utils/korean.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../view_models/pet_management_view_model.dart';
import '../../widgets/glucose_chart.dart';
import '../../widgets/pet_app_bar.dart';
import '../../widgets/record_timeline.dart';
import '../../widgets/status_pill.dart';
import '../book/care_plan_sheet.dart';
import '../home/widgets/record_entry_bottom_sheet.dart';

/// 홈 · 오늘: 열자마자 다음 행동이 보이는 화면.
/// 공통 카드(오늘 기록, 체중) 위에 펫의 질환 모듈 카드(현재는 당뇨)를 쌓는다.
class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).value ?? const [];
    final pet = ref.watch(currentPetProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    if (pet == null) {
      return const Scaffold(backgroundColor: Colors.transparent, appBar: PetAppBar(), body: _NoPetState());
    }

    final records = ref.watch(recordsStreamProvider).value ?? const <Record>[];
    final subtitle = [
      '${now.month}월 ${now.day}일 ${'월화수목금토일'[now.weekday - 1]}요일',
      if (pet.hasDiabetes && pet.diagnosedAt != null) '진단 ${now.difference(pet.diagnosedAt!).inDays + 1}일째',
    ].join(' · ');

    final cards = <Widget>[
      if (pet.hasDiabetes) ..._diabetesCards(context, pet, records, now),
      for (final other in pets.where((p) => p.id != pet.id && p.hasDiabetes && p.dosingTimes.isNotEmpty))
        _OtherPetDose(pet: other, now: now),
      _TodayRecordsCard(pet: pet, records: records, now: now),
      if (records.any((r) => r.weightKg != null)) _WeightCard(records: records),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PetAppBar(subtitle: subtitle),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  List<Widget> _diabetesCards(BuildContext context, Pet pet, List<Record> records, DateTime now) {
    final range = GlucoseRange.forPet(pet);
    final latestGlucose = records.where((r) => r.glucoseValue != null).firstOrNull;
    final hypoNow = latestGlucose != null &&
        now.difference(latestGlucose.recordedAt) < const Duration(hours: 12) &&
        range.classify(latestGlucose.glucoseValue!) == GlucoseStatus.hypo;

    return [
      if (hypoNow) _HypoEmergencyCard(pet: pet, record: latestGlucose),
      if (pet.dosingTimes.isEmpty)
        _SetupPlanCard(pet: pet)
      else
        _NextDoseCard(pet: pet, records: records, now: now),
      if (latestGlucose != null) _LatestGlucoseCard(pet: pet, records: records, latest: latestGlucose, now: now),
    ];
  }
}

// ─── 카드 공통 ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const _Card({required this.child, this.padding = const EdgeInsets.all(16), this.color = kCanvas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kRadiusXl),
        border: Border.all(color: kHairline),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: kSlate, fontSize: 12, fontWeight: FontWeight.w500));
}

String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toString();

String _remaining(Duration d) {
  if (d.inMinutes < 1) return '곧';
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return '$m분 후';
  return m == 0 ? '$h시간 후' : '$h시간 $m분 후';
}

String _slotName(DateTime t) => t.hour < 12 ? '아침' : (t.hour < 17 ? '낮' : '저녁');

// ─── 당뇨 모듈 ─────────────────────────────────────────────────────────────────

class _HypoEmergencyCard extends StatelessWidget {
  final Pet pet;
  final Record record;
  const _HypoEmergencyCard({required this.pet, required this.record});

  @override
  Widget build(BuildContext context) {
    return _Card(
      color: kStatusError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.triangleAlert, color: kOnDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '저혈당 ${record.glucoseValue} · ${DateFormat('HH:mm').format(record.recordedAt)}',
                  style: const TextStyle(color: kOnDark, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '1. 기운이 없거나 떨면 꿀·시럽을 잇몸에 바르세요.\n'
            '2. 15분 뒤 다시 재고, 경련·의식 저하가 있으면 바로 병원으로 가세요.\n'
            '3. 다음 인슐린은 수의사와 상의하기 전까지 투여하지 마세요.',
            style: TextStyle(color: kOnDark, fontSize: 14, height: 1.6),
          ),
          if (pet.vetClinic?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text('병원: ${pet.vetClinic}', style: const TextStyle(color: kOnDark, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _SetupPlanCard extends StatelessWidget {
  final Pet pet;
  const _SetupPlanCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return _Card(
      color: kBrandBlueSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('투여 시간을 정해 주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 6),
          const Text(
            '정해 두면 다음 투여까지 남은 시간과 가족의 투여 현황을 보여 드리고, 같은 회차에 두 번 투여하지 않도록 막아 드려요.',
            style: TextStyle(color: kCharcoal, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => showCarePlanSheet(context, pet),
            style: FilledButton.styleFrom(backgroundColor: kBrandBlue, shape: const StadiumBorder()),
            child: const Text('관리 계획 설정'),
          ),
        ],
      ),
    );
  }
}

class _NextDoseCard extends ConsumerWidget {
  final Pet pet;
  final List<Record> records;
  final DateTime now;
  const _NextDoseCard({required this.pet, required this.records, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = nextDose(pet.dosingTimes, records, now)!;
    final today = doseSlotsFor(now, pet.dosingTimes, records, now);
    final lastGiven = today.lastWhere((s) => s.state == DoseSlotState.given, orElse: () => next);
    final missed = today.where((s) => s.state == DoseSlotState.missed).toList();
    final isDue = next.state == DoseSlotState.due;

    final dose = pet.insulinUnitIu;
    final insulin = [
      if (pet.insulinType != null) pet.insulinType!.split('(').first,
      if (dose != null) '${_num(dose)} IU',
    ].join(' ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDue ? const [kWarmCoral, kBrandWarn] : const [kHeroDarkFrom, kHeroDarkTo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isDue ? '지금 투여할 시간' : '다음 투여',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              StatusPill(
                label: isDue ? '${_slotName(next.scheduledAt)} 회차' : _remaining(next.scheduledAt.difference(now)),
                foreground: kOnDark,
                background: Colors.white24,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(next.scheduledAt),
                style: const TextStyle(color: kOnDark, fontSize: 34, fontWeight: FontWeight.w700, height: 1.1, fontFeatures: kTabularFigures),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(insulin, style: const TextStyle(color: kOnDark, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (pet.insulinConcentration != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StatusPill(label: pet.insulinConcentration!, foreground: kOnDark, background: Colors.white24),
                ),
              ],
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white24)),
          if (lastGiven.state == DoseSlotState.given)
            _GivenBy(slot: lastGiven)
          else
            const Text('오늘 아직 투여 기록이 없어요', style: TextStyle(color: kOnDark, fontSize: 14)),
          for (final m in missed) ...[
            const SizedBox(height: 6),
            Text(
              '${_slotName(m.scheduledAt)} ${DateFormat('HH:mm').format(m.scheduledAt)} 회차 기록이 없어요',
              style: const TextStyle(color: kOnDark, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          if (isDue) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => showRecordEntrySheet(context, initialKinds: {EntryKind.insulin}),
                style: FilledButton.styleFrom(
                  backgroundColor: kOnDark,
                  foregroundColor: kInk,
                  shape: const StadiumBorder(),
                ),
                child: const Text('투여 기록하기', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GivenBy extends ConsumerWidget {
  final DoseSlot slot;
  const _GivenBy({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = slot.record!;
    final who = ref.watch(writerNameProvider(r.writerId));
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: Colors.white24,
          child: Text(who.characters.first, style: const TextStyle(color: kOnDark, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_slotName(slot.scheduledAt)} ${subjectOf(who)} ${DateFormat('HH:mm').format(r.recordedAt)}에 ${_num(r.insulinDose ?? 0)} IU 투여 완료',
            style: const TextStyle(color: kOnDark, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _LatestGlucoseCard extends StatelessWidget {
  final Pet pet;
  final List<Record> records;
  final Record latest;
  final DateTime now;
  const _LatestGlucoseCard({required this.pet, required this.records, required this.latest, required this.now});

  @override
  Widget build(BuildContext context) {
    final range = GlucoseRange.forPet(pet);
    final status = range.classify(latest.glucoseValue!);
    const typeLabels = {'pre_meal': '식전', 'post_meal': '식후', 'fasting': '공복', 'nadir': 'nadir', 'spot': '임의'};

    // 하루 전 같은 시간대(±4시간) 측정값과 비교
    final dayBefore = latest.recordedAt.subtract(const Duration(days: 1));
    Record? compare;
    for (final r in records) {
      if (r.glucoseValue == null) continue;
      final gap = r.recordedAt.difference(dayBefore).abs();
      if (gap > const Duration(hours: 4)) continue;
      if (compare == null || gap < compare.recordedAt.difference(dayBefore).abs()) compare = r;
    }
    final delta = compare == null ? null : latest.glucoseValue! - compare.glucoseValue!;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Label('최신 혈당 · ${DateFormat('HH:mm').format(latest.recordedAt)}'
                  '${typeLabels[latest.glucoseType] != null ? ' ${typeLabels[latest.glucoseType]}' : ''}'),
              const Spacer(),
              StatusPill.glucose(status),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${latest.glucoseValue}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: status == GlucoseStatus.inRange ? kInk : glucoseStatusColor(status),
                  fontFeatures: kTabularFigures,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 5),
                child: Text('mg/dL', style: TextStyle(color: kSlate, fontSize: 12)),
              ),
              const Spacer(),
              if (delta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '어제 이맘때보다 ${delta > 0 ? '+' : '−'}${delta.abs()}',
                    style: const TextStyle(color: kSlate, fontSize: 12, fontWeight: FontWeight.w600, fontFeatures: kTabularFigures),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GlucoseChart(
            records: records,
            range: range,
            from: now.subtract(const Duration(hours: 48)),
            to: now,
            compact: true,
            height: 64,
          ),
          const SizedBox(height: 2),
          const _Label('최근 48시간'),
        ],
      ),
    );
  }
}

class _OtherPetDose extends ConsumerWidget {
  final Pet pet;
  final DateTime now;
  const _OtherPetDose({required this.pet, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(petRecordsProvider(pet.id)).value ?? const <Record>[];
    final next = nextDose(pet.dosingTimes, records, now);
    if (next == null) return const SizedBox.shrink();
    final isDue = next.state == DoseSlotState.due;
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => ref.read(selectedPetIdProvider.notifier).selectPet(pet.id),
        child: Row(
          children: [
            Icon(pet.isCat ? LucideIcons.cat : LucideIcons.dog, size: 18, color: kCharcoal),
            const SizedBox(width: 8),
            Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w600, color: kInk)),
            const Spacer(),
            Text(
              isDue
                  ? '지금 투여할 시간'
                  : '다음 투여 ${DateFormat('HH:mm').format(next.scheduledAt)} · ${_remaining(next.scheduledAt.difference(now))}',
              style: TextStyle(color: isDue ? kStatusWarn : kSlate, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 공통 카드 ─────────────────────────────────────────────────────────────────

class _TodayRecordsCard extends StatelessWidget {
  final Pet pet;
  final List<Record> records;
  final DateTime now;
  const _TodayRecordsCard({required this.pet, required this.records, required this.now});

  @override
  Widget build(BuildContext context) {
    final start = DateTime(now.year, now.month, now.day);
    final todays = records.where((r) => !r.recordedAt.isBefore(start)).toList();
    final entries = buildTimeline(todays);
    final summary = DaySummary.of(todays, dosesPlanned: pet.dosingTimes.length);
    final range = GlucoseRange.forPet(pet);

    return _Card(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('오늘 기록', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                const Spacer(),
                _Label([
                  if (pet.hasDiabetes && pet.dosingTimes.isNotEmpty) '투여 ${summary.dosesGiven}/${summary.dosesPlanned}',
                  if (summary.glucoseValues.isNotEmpty) '혈당 ${summary.glucoseValues.length}회',
                ].join(' · ')),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  const Expanded(child: Text('아직 오늘 기록이 없어요', style: TextStyle(color: kSlate))),
                  TextButton(onPressed: () => showRecordEntrySheet(context), child: const Text('기록 추가')),
                ],
              ),
            )
          else
            for (final e in entries) TimelineRow(entry: e, range: range),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/home/trends'),
              child: const Text('지난 기록 보기', style: TextStyle(color: kBrandBlueDeep)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final List<Record> records;
  const _WeightCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final weights = records.where((r) => r.weightKg != null).toList();
    final latest = weights.first;
    // 7일 이상 전의 가장 가까운 측정과 비교 (수의 가이드라인은 주 단위 변화율을 본다)
    final base = weights.skip(1).where((r) => latest.recordedAt.difference(r.recordedAt).inDays >= 6).firstOrNull;
    final pct = base == null ? null : (latest.weightKg! - base.weightKg!) / base.weightKg! * 100;

    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(LucideIcons.scale, size: 18, color: kTypeWeight),
          const SizedBox(width: 10),
          const Text('체중', style: TextStyle(color: kCharcoal, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Text(
            '${latest.weightKg!.toStringAsFixed(2)} kg',
            style: const TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w700, fontFeatures: kTabularFigures),
          ),
          const Spacer(),
          Text(
            pct == null
                ? DateFormat('M/d 측정').format(latest.recordedAt)
                : '${DateFormat('M/d').format(base!.recordedAt)} 대비 ${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%',
            style: const TextStyle(color: kSlate, fontSize: 12, fontWeight: FontWeight.w600, fontFeatures: kTabularFigures),
          ),
        ],
      ),
    );
  }
}

class _NoPetState extends StatelessWidget {
  const _NoPetState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.pawPrint, color: kStone, size: 56),
            const SizedBox(height: 20),
            const Text('아직 등록된 반려동물이 없어요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kInk)),
            const SizedBox(height: 10),
            const Text(
              '강아지, 고양이 모두 등록할 수 있어요.\n건강수첩에서 우리 아이를 등록해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: kSlate, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/home/book'),
              icon: const Icon(LucideIcons.plus),
              label: const Text('반려동물 등록하기'),
              style: FilledButton.styleFrom(
                backgroundColor: kBrandBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
