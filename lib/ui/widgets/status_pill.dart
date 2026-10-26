import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/glucose.dart';
import '../../l10n/labels.dart';
import '../../l10n/l10n.dart';

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

  factory StatusPill.glucose(GlucoseStatus status, AppLocalizations l) {
    final (fg, bg) = glucoseStatusStyle(status);
    return StatusPill(
      label: glucoseStatusLabel(l, status),
      foreground: fg,
      background: bg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(kRadiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 혈당 상태의 글자색, 바탕색. 표시 이름은 glucoseStatusLabel.
(Color, Color) glucoseStatusStyle(GlucoseStatus status) {
  return switch (status) {
    GlucoseStatus.hypo => (kStatusError, kStatusErrorSoft),
    GlucoseStatus.low => (kStatusWarn, kStatusWarnSoft),
    GlucoseStatus.inRange => (kStatusOk, kStatusOkSoft),
    GlucoseStatus.high => (kStatusWarn, kStatusWarnSoft),
    GlucoseStatus.veryHigh => (kStatusSevere, kStatusErrorSoft),
  };
}

Color glucoseStatusColor(GlucoseStatus status) => glucoseStatusStyle(status).$1;
