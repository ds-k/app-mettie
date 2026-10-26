import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/record.dart';
import '../../../domain/glucose.dart';
import '../../../domain/timeline.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/labels.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../widgets/glucose_chart.dart';
import '../../widgets/pet_app_bar.dart';
import '../../widgets/record_timeline.dart';
import '../../widgets/status_pill.dart';

/// 추이: "좋아지고 있나"에 답하는 화면. 아래로 내리면 같은 기간의 기록 타임라인이 이어진다.
class TrendsView extends ConsumerStatefulWidget {
  const TrendsView({super.key});

  @override
  ConsumerState<TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends ConsumerState<TrendsView> {
  int _days = 14;
  final Set<EntryKind> _filter = {};

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(currentPetProvider);
    final records = ref.watch(recordsStreamProvider).value ?? const <Record>[];
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    final l = context.l10n;
    if (pet == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PetAppBar(title: l.navTrends),
        body: Center(
          child: Text(
            l.trendsAddPetFirst,
            style: const TextStyle(color: kSlate),
          ),
        ),
      );
    }

    final to = now;
    final from = _days == 1
        ? now.subtract(const Duration(hours: 24))
        : DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: _days - 1));
    final inPeriod = records
        .where((r) => !r.recordedAt.isBefore(from))
        .toList();
    final hasGlucose = inPeriod.any((r) => r.glucoseValue != null);
    final hasWeight = records.any((r) => r.weightKg != null);
    final range = GlucoseRange.forPet(pet);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PetAppBar(
        subtitle: l.trendsSubtitle(
          DateFormat.Md(l.localeName).format(from),
          DateFormat.Md(l.localeName).format(to),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList.list(
              children: [
                _PeriodSelector(
                  value: _days,
                  onChanged: (d) => setState(() => _days = d),
                ),
                const SizedBox(height: 12),
                if (hasGlucose) ...[
                  _Card(
                    title: l.kindGlucose,
                    trailing: l.trendsTarget(range.min, range.max),
                    child: Column(
                      children: [
                        GlucoseChart(
                          records: inPeriod,
                          range: range,
                          from: from,
                          to: to,
                          height: 210,
                        ),
                        const SizedBox(height: 8),
                        const _ChartLegend(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TimeInRangeCard(
                    values: inPeriod
                        .where((r) => r.glucoseValue != null)
                        .map((r) => r.glucoseValue!),
                    range: range,
                  ),
                  const SizedBox(height: 12),
                  _StatsCard(
                    summary: GlucosePeriodSummary.of(records, from, to),
                    range: range,
                    days: _days,
                  ),
                  const SizedBox(height: 12),
                ] else if (pet.hasDiabetes) ...[
                  _Card(
                    title: l.kindGlucose,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          l.trendsNoGlucose,
                          style: const TextStyle(color: kSlate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasWeight) ...[
                  _WeightTrendCard(records: records, pet: pet),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Text(
                  l.trendsRecords,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 8),
                _FilterChips(
                  selected: _filter,
                  showInsulin: pet.hasDiabetes,
                  onChanged: (k) => setState(() {
                    if (k == null) {
                      _filter.clear();
                    } else if (!_filter.remove(k)) {
                      _filter.add(k);
                    }
                  }),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 4),
            sliver: RecordTimelineSliver(
              records: inPeriod,
              pet: pet,
              filter: _filter,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;
  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    decoration: BoxDecoration(
      color: kCanvas,
      borderRadius: BorderRadius.circular(kRadiusXl),
      border: Border.all(color: kHairline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: kSlate, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _PeriodSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PeriodSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (final d in const [1, 7, 14, 30])
          ButtonSegment(value: d, label: Text(context.l10n.periodDays(d))),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: kCanvas,
        selectedBackgroundColor: kInk,
        selectedForegroundColor: kOnDark,
        foregroundColor: kCharcoal,
        side: const BorderSide(color: kHairline),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: kSlate, fontSize: 11)),
      ],
    );
    final l = context.l10n;
    Widget dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item(
          Container(width: 12, height: 8, color: kStatusOkSoft),
          l.legendTarget,
        ),
        item(dot(kBrandBlue), l.legendReading),
        item(dot(kStatusError), l.legendHypo),
        item(Container(width: 6, height: 6, color: kTypeInsulin), l.legendDose),
        item(
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(border: Border.all(color: kStatusWarn)),
          ),
          l.legendSkipped,
        ),
      ],
    );
  }
}

class _TimeInRangeCard extends StatelessWidget {
  final Iterable<int> values;
  final GlucoseRange range;
  const _TimeInRangeCard({required this.values, required this.range});

  @override
  Widget build(BuildContext context) {
    final d = GlucoseDistribution.of(values, range);
    final segments = [
      for (final s in GlucoseStatus.values)
        if (d.counts[s]! > 0) (s, d.counts[s]!),
    ];
    final l = context.l10n;
    return _Card(
      title: l.tirTitle,
      trailing: l.tirReadings(d.total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(d.timeInRange * 100).round()}%',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kStatusOk,
              fontFeatures: kTabularFigures,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final (s, c) in segments)
                    Expanded(
                      flex: c,
                      child: Container(
                        color: glucoseStatusColor(s),
                        margin: const EdgeInsets.only(right: 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final (s, c) in segments)
                Text(
                  '${glucoseStatusLabel(l, s)} ${(c / d.total * 100).round()}%',
                  style: TextStyle(
                    color: glucoseStatusColor(s),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final GlucosePeriodSummary summary;
  final GlucoseRange range;
  final int days;
  const _StatsCard({
    required this.summary,
    required this.range,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    Widget stat(
      String label,
      String value,
      String? note, {
      Color valueColor = kInk,
      Color noteColor = kSlate,
    }) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kSlate, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: kTabularFigures,
            ),
          ),
          if (note != null)
            Text(
              note,
              style: TextStyle(
                color: noteColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );

    final delta = summary.averageDelta;
    final lowStatus = summary.lowest == null
        ? null
        : range.classify(summary.lowest!.glucoseValue!);
    final highStatus = summary.highest == null
        ? null
        : range.classify(summary.highest!.glucoseValue!);
    final l = context.l10n;
    String when(Record r) =>
        DateFormat.Md(l.localeName).add_Hm().format(r.recordedAt);

    return _Card(
      title: l.summaryTitle,
      trailing: l.summaryComparedTo(days),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stat(
            l.summaryAverage,
            summary.average?.round().toString() ?? '–',
            delta == null
                ? null
                : '${delta <= 0 ? '↓' : '↑'} ${delta.abs().round()}',
            noteColor: delta == null
                ? kSlate
                : (delta <= 0 ? kStatusOk : kStatusWarn),
          ),
          stat(
            l.summaryLowest,
            summary.lowest?.glucoseValue.toString() ?? '–',
            summary.lowest == null ? null : when(summary.lowest!),
            valueColor: lowStatus == null || lowStatus == GlucoseStatus.inRange
                ? kInk
                : glucoseStatusColor(lowStatus),
          ),
          stat(
            l.summaryHighest,
            summary.highest?.glucoseValue.toString() ?? '–',
            summary.highest == null ? null : when(summary.highest!),
            valueColor:
                highStatus == null || highStatus == GlucoseStatus.inRange
                ? kInk
                : glucoseStatusColor(highStatus),
          ),
        ],
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  final List<Record> records;
  final Pet pet;
  const _WeightTrendCard({required this.records, required this.pet});

  @override
  Widget build(BuildContext context) {
    final weights = records.where((r) => r.weightKg != null).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final first = weights.first, last = weights.last;
    final pct = weights.length < 2
        ? null
        : (last.weightKg! - first.weightKg!) / first.weightKg! * 100;
    // 2 kg 고양이부터 40 kg 대형견까지 변화가 보이도록 축을 측정값에 맞춘다
    final values = weights.map((w) => w.weightKg!);
    final lo = values.reduce((a, b) => a < b ? a : b),
        hi = values.reduce((a, b) => a > b ? a : b);
    final pad = ((hi - lo) * 0.5).clamp(0.1, double.infinity);
    final t0 = first.recordedAt;
    final l = context.l10n;

    return _Card(
      title: l.weightLabel,
      trailing: pct == null
          ? '${last.weightKg!.toStringAsFixed(2)} kg'
          : l.weightTrendTrailing(
              last.weightKg!.toStringAsFixed(2),
              DateFormat.Md(l.localeName).format(first.recordedAt),
              '${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%',
            ),
      child: weights.length < 2
          ? const SizedBox.shrink()
          : SizedBox(
              height: 90,
              child: LineChart(
                LineChartData(
                  minY: lo - pad,
                  maxY: hi + pad,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final w in weights)
                          FlSpot(
                            w.recordedAt.difference(t0).inHours.toDouble(),
                            w.weightKg!,
                          ),
                      ],
                      color: kTypeWeight,
                      barWidth: 2,
                      dotData: FlDotData(
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 3,
                          color: kTypeWeight,
                          strokeWidth: 1,
                          strokeColor: kCanvas,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final Set<EntryKind> selected;
  final bool showInsulin;
  final ValueChanged<EntryKind?> onChanged;
  const _FilterChips({
    required this.selected,
    required this.showInsulin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final options = [
      (null, l.kindAll),
      (EntryKind.glucose, l.kindGlucose),
      if (showInsulin) (EntryKind.insulin, l.kindInsulin),
      (EntryKind.meal, l.kindMeal),
      (EntryKind.weight, l.kindWeight),
      (EntryKind.observation, l.kindObservation),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (kind, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: kind == null ? selected.isEmpty : selected.contains(kind),
            showCheckmark: false,
            selectedColor: kInk,
            backgroundColor: kCanvas,
            side: const BorderSide(color: kHairline),
            labelStyle: TextStyle(
              color: (kind == null ? selected.isEmpty : selected.contains(kind))
                  ? kOnDark
                  : kCharcoal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            shape: const StadiumBorder(),
            onSelected: (_) => onChanged(kind),
          ),
      ],
    );
  }
}
