import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/record.dart';
import '../../domain/glucose.dart';
import 'status_pill.dart';

/// 기간 혈당 그래프: 목표 범위 띠, 저혈당 기준선, 측정값 점(상태 색), 투여 눈금.
/// [compact]는 홈의 48시간 미니 그래프용으로 축과 눈금을 숨긴다.
class GlucoseChart extends StatelessWidget {
  final List<Record> records;
  final GlucoseRange range;
  final DateTime from;
  final DateTime to;
  final bool compact;
  final double height;

  const GlucoseChart({
    super.key,
    required this.records,
    required this.range,
    required this.from,
    required this.to,
    this.compact = false,
    this.height = 200,
  });

  double _x(DateTime t) => t.difference(from).inMinutes.toDouble();

  @override
  Widget build(BuildContext context) {
    final glucose = records
        .where((r) => r.glucoseValue != null && !r.recordedAt.isBefore(from) && !r.recordedAt.isAfter(to))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final doses = records
        .where((r) => r.injectionStatus != null && !r.recordedAt.isBefore(from) && !r.recordedAt.isAfter(to))
        .toList();

    final maxValue = glucose.fold<int>(range.max, (m, r) => r.glucoseValue! > m ? r.glucoseValue! : m);
    final minY = compact ? 40.0 : 0.0;
    final maxY = ((maxValue + 20) / 100).ceil() * 100.0;
    // 투여 눈금은 그래프 아래 띠에 놓는다
    final doseY = compact ? minY : 20.0;
    final spanMinutes = to.difference(from).inMinutes.toDouble();

    final glucoseSpots = [for (final r in glucose) FlSpot(_x(r.recordedAt), r.glucoseValue!.toDouble())];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spanMinutes,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: range.min.toDouble(),
              y2: range.max.toDouble(),
              color: kStatusOkSoft.withValues(alpha: 0.7),
            ),
          ]),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: range.hypo.toDouble(),
              color: kStatusError.withValues(alpha: 0.8),
              strokeWidth: 1,
              dashArray: [4, 3],
            ),
          ]),
          gridData: FlGridData(
            show: !compact,
            drawVerticalLine: false,
            horizontalInterval: 100,
            getDrawingHorizontalLine: (_) => const FlLine(color: kHairline, strokeWidth: 0.8),
          ),
          borderData: FlBorderData(show: false),
          titlesData: compact
              ? const FlTitlesData(show: false)
              : FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 100,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: kSlate, fontSize: 10, fontFeatures: kTabularFigures),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: _labelInterval(spanMinutes),
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        final t = from.add(Duration(minutes: value.toInt()));
                        final label = spanMinutes <= 60 * 24 * 1.5
                            ? DateFormat('HH:mm').format(t)
                            : DateFormat('M/d').format(t);
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(label, style: const TextStyle(color: kSlate, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
          lineTouchData: LineTouchData(
            enabled: !compact,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => kInk,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  if (s.barIndex == 0)
                    LineTooltipItem(
                      '${s.y.toInt()} mg/dL\n${DateFormat('M/d HH:mm').format(from.add(Duration(minutes: s.x.toInt())))}',
                      const TextStyle(color: kOnDark, fontSize: 11, fontWeight: FontWeight.w600),
                    )
                  else
                    null,
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: glucoseSpots,
              color: kBrandBlue.withValues(alpha: compact ? 1 : 0.45),
              barWidth: compact ? 1.6 : 1,
              dotData: FlDotData(
                getDotPainter: (spot, _, _, index) {
                  final status = range.classify(spot.y.toInt());
                  final isLast = index == glucoseSpots.length - 1;
                  return FlDotCirclePainter(
                    radius: status == GlucoseStatus.hypo || (compact && isLast) ? 4 : 2.6,
                    color: status == GlucoseStatus.inRange && !(compact && isLast)
                        ? kBrandBlue
                        : glucoseStatusColor(status),
                    strokeWidth: 1,
                    strokeColor: kCanvas,
                  );
                },
              ),
            ),
            if (!compact)
              LineChartBarData(
                spots: [for (final d in doses) FlSpot(_x(d.recordedAt), doseY)],
                barWidth: 0,
                color: Colors.transparent,
                dotData: FlDotData(
                  getDotPainter: (spot, _, _, index) {
                    final given = doses[index].injectionStatus == 'given';
                    return FlDotSquarePainter(
                      size: 5,
                      color: given ? kTypeInsulin : kCanvas,
                      strokeWidth: given ? 0 : 1.2,
                      strokeColor: kStatusWarn,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _labelInterval(double spanMinutes) {
    const day = 60.0 * 24;
    if (spanMinutes <= day * 1.5) return 60 * 6;
    if (spanMinutes <= day * 8) return day * 2;
    if (spanMinutes <= day * 15) return day * 4;
    return day * 7;
  }
}
