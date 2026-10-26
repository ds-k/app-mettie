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
import '../../../l10n/l10n.dart';
import '../../../l10n/labels.dart';
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
      return const Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PetAppBar(),
        body: _NoPetState(),
      );
    }

    final records = ref.watch(recordsStreamProvider).value ?? const <Record>[];
    final l = context.l10n;
    final subtitle = [
      DateFormat.MMMMEEEEd(l.localeName).format(now),
      if (pet.hasDiabetes && pet.diagnosedAt != null)
        l.todayDiagnosisDay(now.difference(pet.diagnosedAt!).inDays + 1),
    ].join(' · ');

    final cards = <Widget>[
      if (pet.hasDiabetes) ..._diabetesCards(context, pet, records, now),
      for (final other in pets.where(
        (p) => p.id != pet.id && p.hasDiabetes && p.dosingTimes.isNotEmpty,
      ))
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

  List<Widget> _diabetesCards(
    BuildContext context,
    Pet pet,
    List<Record> records,
    DateTime now,
  ) {
    final range = GlucoseRange.forPet(pet);
    final latestGlucose = records
        .where((r) => r.glucoseValue != null)
        .firstOrNull;
    final hypoNow =
        latestGlucose != null &&
        now.difference(latestGlucose.recordedAt) < const Duration(hours: 12) &&
        range.classify(latestGlucose.glucoseValue!) == GlucoseStatus.hypo;

    return [
      if (hypoNow) _HypoEmergencyCard(pet: pet, record: latestGlucose),
      if (pet.dosingTimes.isEmpty)
        _SetupPlanCard(pet: pet)
      else
        _NextDoseCard(pet: pet, records: records, now: now),
      if (latestGlucose != null)
        _LatestGlucoseCard(
          pet: pet,
          records: records,
          latest: latestGlucose,
          now: now,
        ),
    ];
  }
}

// ─── 카드 공통 ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = kCanvas,
  });

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
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: kSlate,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toString();

String _remaining(AppLocalizations l, Duration d) {
  if (d.inMinutes < 1) return l.remainingSoon;
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return l.remainingMinutes(m);
  return m == 0 ? l.remainingHours(h) : l.remainingHoursMinutes(h, m);
}

String _slotName(AppLocalizations l, DateTime t) =>
    t.hour < 12 ? l.slotMorning : (t.hour < 17 ? l.slotMidday : l.slotEvening);

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
                  context.l10n.hypoCardTitle(
                    record.glucoseValue!,
                    DateFormat('HH:mm').format(record.recordedAt),
                  ),
                  style: const TextStyle(
                    color: kOnDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.hypoCardSteps,
            style: const TextStyle(color: kOnDark, fontSize: 14, height: 1.6),
          ),
          if (pet.vetClinic?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.hypoCardVet(pet.vetClinic!),
              style: const TextStyle(
                color: kOnDark,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          Text(
            context.l10n.setupPlanTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.setupPlanBody,
            style: const TextStyle(color: kCharcoal, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => showCarePlanSheet(context, pet),
            style: FilledButton.styleFrom(
              backgroundColor: kBrandBlue,
              shape: const StadiumBorder(),
            ),
            child: Text(context.l10n.setupPlanButton),
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
  const _NextDoseCard({
    required this.pet,
    required this.records,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final next = nextDose(pet.dosingTimes, records, now)!;
    final today = doseSlotsFor(now, pet.dosingTimes, records, now);
    final lastGiven = today.lastWhere(
      (s) => s.state == DoseSlotState.given,
      orElse: () => next,
    );
    final missed = today.where((s) => s.state == DoseSlotState.missed).toList();
    final isDue = next.state == DoseSlotState.due;

    final dose = pet.insulinUnitIu;
    final insulin = [
      if (pet.insulinType != null) insulinDisplayName(l, pet.insulinType!),
      if (dose != null) '${_num(dose)} IU',
    ].join(' ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDue
              ? const [kWarmCoral, kBrandWarn]
              : const [kHeroDarkFrom, kHeroDarkTo],
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
              Text(
                isDue ? l.doseDueNow : l.doseNext,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: isDue
                    ? l.doseSlotLabel(_slotName(l, next.scheduledAt))
                    : _remaining(l, next.scheduledAt.difference(now)),
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
                style: const TextStyle(
                  color: kOnDark,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  fontFeatures: kTabularFigures,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  insulin,
                  style: const TextStyle(
                    color: kOnDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (pet.insulinConcentration != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StatusPill(
                    label: pet.insulinConcentration!,
                    foreground: kOnDark,
                    background: Colors.white24,
                  ),
                ),
              ],
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.white24),
          ),
          if (lastGiven.state == DoseSlotState.given)
            _GivenBy(slot: lastGiven)
          else
            Text(
              l.doseNoneToday,
              style: const TextStyle(color: kOnDark, fontSize: 14),
            ),
          for (final m in missed) ...[
            const SizedBox(height: 6),
            Text(
              l.doseMissedSlot(
                _slotName(l, m.scheduledAt),
                DateFormat('HH:mm').format(m.scheduledAt),
              ),
              style: const TextStyle(
                color: kOnDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (isDue) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => showRecordEntrySheet(
                  context,
                  initialKinds: {EntryKind.insulin},
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: kOnDark,
                  foregroundColor: kInk,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  l.doseRecordButton,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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
    final l = context.l10n;
    final writer = ref.watch(writerNameProvider(r.writerId));
    final who = writer.label(l);
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: Colors.white24,
          child: Text(
            who.characters.first,
            style: const TextStyle(
              color: kOnDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l.doseGivenBy(
              _slotName(l, slot.scheduledAt),
              writer.subject(l),
              DateFormat('HH:mm').format(r.recordedAt),
              _num(r.insulinDose ?? 0),
            ),
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
  const _LatestGlucoseCard({
    required this.pet,
    required this.records,
    required this.latest,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final range = GlucoseRange.forPet(pet);
    final status = range.classify(latest.glucoseValue!);
    final l = context.l10n;
    final typeLabel = glucoseTypeLabel(l, latest.glucoseType);

    // 하루 전 같은 시간대(±4시간) 측정값과 비교
    final dayBefore = latest.recordedAt.subtract(const Duration(days: 1));
    Record? compare;
    for (final r in records) {
      if (r.glucoseValue == null) continue;
      final gap = r.recordedAt.difference(dayBefore).abs();
      if (gap > const Duration(hours: 4)) continue;
      if (compare == null ||
          gap < compare.recordedAt.difference(dayBefore).abs()) {
        compare = r;
      }
    }
    final delta = compare == null
        ? null
        : latest.glucoseValue! - compare.glucoseValue!;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Label(
                l.latestGlucoseLabel(
                  '${DateFormat('HH:mm').format(latest.recordedAt)}${typeLabel != null ? ' $typeLabel' : ''}',
                ),
              ),
              const Spacer(),
              StatusPill.glucose(status, l),
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
                  color: status == GlucoseStatus.inRange
                      ? kInk
                      : glucoseStatusColor(status),
                  fontFeatures: kTabularFigures,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 5),
                child: Text(
                  'mg/dL',
                  style: TextStyle(color: kSlate, fontSize: 12),
                ),
              ),
              const Spacer(),
              if (delta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    l.glucoseVsYesterday(
                      '${delta > 0 ? '+' : '−'}${delta.abs()}',
                    ),
                    style: const TextStyle(
                      color: kSlate,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: kTabularFigures,
                    ),
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
          _Label(l.last48h),
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
    final records =
        ref.watch(petRecordsProvider(pet.id)).value ?? const <Record>[];
    final next = nextDose(pet.dosingTimes, records, now);
    if (next == null) return const SizedBox.shrink();
    final isDue = next.state == DoseSlotState.due;
    final l = context.l10n;
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => ref.read(selectedPetIdProvider.notifier).selectPet(pet.id),
        child: Row(
          children: [
            Icon(
              pet.isCat ? LucideIcons.cat : LucideIcons.dog,
              size: 18,
              color: kCharcoal,
            ),
            const SizedBox(width: 8),
            Text(
              pet.name,
              style: const TextStyle(fontWeight: FontWeight.w600, color: kInk),
            ),
            const Spacer(),
            Text(
              isDue
                  ? l.doseDueNow
                  : l.otherPetNextDose(
                      DateFormat('HH:mm').format(next.scheduledAt),
                      _remaining(l, next.scheduledAt.difference(now)),
                    ),
              style: TextStyle(
                color: isDue ? kStatusWarn : kSlate,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
  const _TodayRecordsCard({
    required this.pet,
    required this.records,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateTime(now.year, now.month, now.day);
    final todays = records.where((r) => !r.recordedAt.isBefore(start)).toList();
    final entries = buildTimeline(todays);
    final summary = DaySummary.of(todays, dosesPlanned: pet.dosingTimes.length);
    final range = GlucoseRange.forPet(pet);
    final l = context.l10n;

    return _Card(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  l.todayRecords,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
                const Spacer(),
                _Label(
                  [
                    if (pet.hasDiabetes && pet.dosingTimes.isNotEmpty)
                      l.tlDoses(summary.dosesGiven, summary.dosesPlanned),
                    if (summary.glucoseValues.isNotEmpty)
                      l.todayGlucoseCount(summary.glucoseValues.length),
                  ].join(' · '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.todayEmpty,
                      style: const TextStyle(color: kSlate),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showRecordEntrySheet(context),
                    child: Text(l.navAddRecord),
                  ),
                ],
              ),
            )
          else
            for (final e in entries) TimelineRow(entry: e, range: range),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/home/trends'),
              child: Text(
                l.viewPastRecords,
                style: const TextStyle(color: kBrandBlueDeep),
              ),
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
    final base = weights
        .skip(1)
        .where((r) => latest.recordedAt.difference(r.recordedAt).inDays >= 6)
        .firstOrNull;
    final pct = base == null
        ? null
        : (latest.weightKg! - base.weightKg!) / base.weightKg! * 100;
    final l = context.l10n;
    final md = DateFormat.Md(l.localeName);

    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(LucideIcons.scale, size: 18, color: kTypeWeight),
          const SizedBox(width: 10),
          Text(
            l.weightLabel,
            style: const TextStyle(
              color: kCharcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${latest.weightKg!.toStringAsFixed(2)} kg',
            style: const TextStyle(
              color: kInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: kTabularFigures,
            ),
          ),
          const Spacer(),
          Text(
            pct == null
                ? l.weightMeasuredOn(md.format(latest.recordedAt))
                : l.weightChangeSince(
                    md.format(base!.recordedAt),
                    '${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%',
                  ),
            style: const TextStyle(
              color: kSlate,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: kTabularFigures,
            ),
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
            Text(
              context.l10n.noPetTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.noPetBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: kSlate, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/home/book'),
              icon: const Icon(LucideIcons.plus),
              label: Text(context.l10n.noPetButton),
              style: FilledButton.styleFrom(
                backgroundColor: kBrandBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
