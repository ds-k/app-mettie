import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/glucose.dart';

/// 작은 상태 배지. 색은 의미가 있을 때만 쓰고, 기본은 회색.
class StatusPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const StatusPill({
    super.key,
    required this.label,
    this.foreground = kSlate,
    this.background = kSurfaceSoft,
  });

  factory StatusPill.glucose(GlucoseStatus status) {
    final (label, fg, bg) = glucoseStatusStyle(status);
    return StatusPill(label: label, foreground: fg, background: bg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(kRadiusFull)),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 혈당 상태의 표시 이름, 글자색, 바탕색.
(String, Color, Color) glucoseStatusStyle(GlucoseStatus status) {
  return switch (status) {
    GlucoseStatus.hypo => ('저혈당', kStatusError, kStatusErrorSoft),
    GlucoseStatus.low => ('낮음', kStatusWarn, kStatusWarnSoft),
    GlucoseStatus.inRange => ('목표 범위', kStatusOk, kStatusOkSoft),
    GlucoseStatus.high => ('높음', kStatusWarn, kStatusWarnSoft),
    GlucoseStatus.veryHigh => ('매우 높음', kStatusSevere, kStatusErrorSoft),
  };
}

Color glucoseStatusColor(GlucoseStatus status) => glucoseStatusStyle(status).$2;
