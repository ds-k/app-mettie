import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../data/models/record.dart';
import '../../domain/glucose.dart';
import '../../domain/timeline.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../view_models/dashboard_view_model.dart';
import '../views/dashboard/widgets/dashboard_record_row.dart';
import 'status_pill.dart';

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// 인슐린 용량은 소수점 한 자리를 항상 보여 준다 (2 → 2.0).
String formatDose(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toString();

const _foodOrder = {'wet': 0, 'dry': 1, 'raw': 2, 'mixed': 3};

/// 관찰 기록을 화면 언어로 바꾼다.
List<String> observationLabels(AppLocalizations l, Record r) => [
  if (r.waterIntake == 'increased') l.obsDrinkMore,
  if (r.waterIntake == 'decreased') l.obsDrinkLess,
  if (r.urination == 'polyuria') l.obsUrinateMore,
  if (r.urination == 'decreased') l.obsUrinateLess,
  if (r.appetite == 'partial') l.appetitePoor,
  if (r.appetite == 'anorexic') l.obsNoAppetite,
  if (r.vomitCount > 0) l.obsVomitCount(r.vomitCount),
  if (r.stoolStatus == 'diarrhea') l.obsDiarrhea,
  if (r.stoolStatus == 'constipation') l.obsConstipation,
  for (final t in r.symptomTags ?? const <String>[]) observationLabel(l, t),
];

String entrySummary(AppLocalizations l, TimelineEntry e) {
  final r = e.primary;
  switch (e.kind) {
    case EntryKind.meal:
      final foods = [
        for (final f
            in [...e.records]..sort(
              (a, b) => (_foodOrder[a.foodType] ?? 9).compareTo(
                _foodOrder[b.foodType] ?? 9,
              ),
            ))
          [
            foodTypeLabel(l, f.foodType) ?? f.foodBrand ?? l.foodGeneric,
            if (f.foodAmountG != null) '${_num(f.foodAmountG!)} g',
          ].join(' '),
      ];
      final poorAppetite = e.records.any(
        (f) => f.appetite == 'partial' || f.appetite == 'anorexic',
      );
      return [...foods, if (poorAppetite) l.appetitePoor].join(' · ');
    case EntryKind.insulin:
      final parts = <String>[
        switch (r.injectionStatus) {
          'skipped' => l.tlInsulinSkipped,
          'partial' => l.tlInsulinPartial(formatDose(r.insulinDose ?? 0)),
          _ => l.tlInsulin(formatDose(r.insulinDose ?? 0)),
        },
        if (r.glucoseValue != null) l.tlGlucose(r.glucoseValue!),
        if (r.foodAmountG != null) l.tlFoodAmount(_num(r.foodAmountG!)),
        if (r.injectionStatus == 'skipped' && (r.notes?.isNotEmpty ?? false))
          r.notes!,
      ];
      return parts.join(' · ');
    case EntryKind.glucose:
      return [
        l.tlGlucose(r.glucoseValue!),
        ?glucoseTypeLabel(l, r.glucoseType),
        if (r.notes?.isNotEmpty ?? false) r.notes!,
      ].join(' · ');
    case EntryKind.weight:
      return l.tlWeight(r.weightKg!.toStringAsFixed(2));
    case EntryKind.observation:
      return [
        ...observationLabels(l, r),
        if (r.notes?.isNotEmpty ?? false) r.notes!,
      ].join(' · ');
  }
}

/// 타임라인 한 줄.
class TimelineRow extends ConsumerWidget {
  final TimelineEntry entry;
  final GlucoseRange? range;

  const TimelineRow({super.key, required this.entry, this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = entry.primary;
    final l = context.l10n;
    final writer = ref.watch(writerNameProvider(r.writerId)).label(l);
    final glucoseStatus = entry.kind == EntryKind.glucose && range != null
        ? range!.classify(r.glucoseValue!)
        : null;

    final Color dot = switch (entry.kind) {
      EntryKind.glucose =>
        glucoseStatus == null || glucoseStatus == GlucoseStatus.inRange
            ? kStatusOk
            : glucoseStatusColor(glucoseStatus),
      EntryKind.insulin =>
        r.injectionStatus == 'skipped' ? kStone : kTypeInsulin,
      EntryKind.meal => kTypeFood,
      EntryKind.weight => kTypeWeight,
      EntryKind.observation => kTypeObservation,
    };

    final Widget badge = switch (entry.kind) {
      EntryKind.glucose when glucoseStatus != null => StatusPill.glucose(
        glucoseStatus,
        l,
      ),
      EntryKind.insulin when r.injectionStatus == 'skipped' => StatusPill(
        label: l.injectionSkipped,
        foreground: kStatusWarn,
        background: kStatusWarnSoft,
      ),
      EntryKind.insulin => StatusPill(
        label: writer,
        foreground: kBrandBlueDeep,
        background: kBrandBlueSoft,
      ),
      _ => Text(writer, style: const TextStyle(color: kStone, fontSize: 11)),
    };

    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                DateFormat('HH:mm').format(entry.at),
                style: const TextStyle(
                  color: kSlate,
                  fontSize: 12,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                entrySummary(l, entry),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kInk,
                  fontSize: 14,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
            const SizedBox(width: 8),
            badge,
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: kCanvas,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in entry.records) DashboardRecordRow(record: r),
          ],
        ),
      ),
    );
  }
}

/// 날짜별로 묶은 타임라인 sliver. 날짜 머리에 하루 요약을 붙인다.
class RecordTimelineSliver extends StatelessWidget {
  final List<Record> records;
  final Pet pet;
  final Set<EntryKind> filter;

  const RecordTimelineSliver({
    super.key,
    required this.records,
    required this.pet,
    this.filter = const {},
  });

  @override
  Widget build(BuildContext context) {
    final entries = buildTimeline(
      records,
    ).where((e) => filter.isEmpty || filter.any(e.contains)).toList();
    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              context.l10n.tlEmptyFiltered,
              style: const TextStyle(color: kSlate),
            ),
          ),
        ),
      );
    }

    final range = GlucoseRange.forPet(pet);
    final byDay = <DateTime, List<Record>>{};
    for (final r in records) {
      final d = DateTime(
        r.recordedAt.year,
        r.recordedAt.month,
        r.recordedAt.day,
      );
      byDay.putIfAbsent(d, () => []).add(r);
    }

    final items = <Object>[];
    DateTime? currentDay;
    for (final e in entries) {
      final d = DateTime(e.at.year, e.at.month, e.at.day);
      if (d != currentDay) {
        items.add(d);
        currentDay = d;
      }
      items.add(e);
    }

    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is DateTime) {
          return _DayHeader(
            day: item,
            summary: DaySummary.of(
              byDay[item] ?? const [],
              dosesPlanned: pet.dosingTimes.length,
            ),
            range: range,
            showDoses: pet.hasDiabetes,
          );
        }
        return TimelineRow(entry: item as TimelineEntry, range: range);
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final DaySummary summary;
  final GlucoseRange range;
  final bool showDoses;

  const _DayHeader({
    required this.day,
    required this.summary,
    required this.range,
    required this.showDoses,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateTime.now();
    final isToday = day == DateTime(today.year, today.month, today.day);
    final dayLabel = DateFormat.MMMEd(l.localeName).format(day);
    final hypoCount = summary.glucoseValues
        .where((v) => range.classify(v) == GlucoseStatus.hypo)
        .length;

    // 문제가 있는 날만 색을 쓴다
    String text;
    Color color = kSlate;
    if (hypoCount > 0) {
      text = l.tlHypoCount(hypoCount);
      color = kStatusError;
    } else if (showDoses && summary.dosesSkipped > 0) {
      final planned = summary.dosesPlanned > 0
          ? summary.dosesPlanned
          : summary.dosesGiven + summary.dosesSkipped;
      text =
          '${l.tlDoses(summary.dosesGiven, planned)} · ${l.tlSkippedCount(summary.dosesSkipped)}';
      color = kStatusWarn;
    } else {
      text = [
        if (showDoses && (summary.dosesPlanned > 0 || summary.dosesGiven > 0))
          l.tlDoses(
            summary.dosesGiven,
            summary.dosesPlanned > 0
                ? summary.dosesPlanned
                : summary.dosesGiven,
          ),
        if (summary.glucoseAverage != null)
          summary.glucoseValues.length == 1
              ? l.tlGlucoseSingle(summary.glucoseValues.single)
              : l.tlGlucoseAverage(summary.glucoseAverage!.round()),
      ].join(' · ');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Text(
            '$dayLabel${isToday ? ' · ${l.tlToday}' : ''}',
            style: const TextStyle(
              color: kCharcoal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            text,
            style: TextStyle(
              color: color,
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
