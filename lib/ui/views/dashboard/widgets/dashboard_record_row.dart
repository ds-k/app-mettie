import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/record.dart';
import '../../../../data/repositories/record_repository.dart';

class DashboardRecordRow extends ConsumerWidget {
  final Record record;

  const DashboardRecordRow({super.key, required this.record});

  String _getRecordTitle(AppLocalizations l, Record record) {
    final hour = record.recordedAt.hour;
    final String timeStr;
    if (hour >= 5 && hour < 11) {
      timeStr = l.rowMorning;
    } else if (hour >= 11 && hour < 16) {
      timeStr = l.rowLunch;
    } else if (hour >= 16 && hour < 22) {
      timeStr = l.rowEvening;
    } else {
      timeStr = l.rowNight;
    }

    if (record.glucoseType == 'pre_meal') return l.rowPreMeal(timeStr);
    if (record.glucoseType == 'post_meal') return l.rowPostMeal(timeStr);
    if (record.glucoseType == 'fasting') return l.rowFasting;
    if (record.glucoseType == 'nadir') return l.rowNadir;

    if (record.insulinDose != null && record.glucoseValue == null) {
      return l.rowInsulin(timeStr);
    }
    if (record.foodAmountG != null && record.glucoseValue == null) {
      return l.rowMeal(timeStr);
    }

    return timeStr;
  }

  Widget _buildHighlightBox({
    IconData? icon,
    required Color boxColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Icon(icon, color: boxColor, size: 20),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kSlate,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: boxColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(unit, style: TextStyle(color: boxColor, fontSize: 14)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: kBrandError,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: kOnDark),
      ),
      confirmDismiss: (direction) async {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.rowDeleteTitle),
            content: Text(context.l10n.rowDeleteBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.commonCancel, style: const TextStyle(color: kSlate)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.l10n.commonDelete, style: const TextStyle(color: kBrandError)),
              ),
            ],
          ),
        );

        if (confirm != true) return false;

        try {
          await ref.read(recordRepositoryProvider).deleteRecord(record.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.l10n.rowDeleted)));
          }
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage(context.l10n, e))));
          }
          return false;
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    DateFormat('HH:mm').format(record.recordedAt),
                    style: const TextStyle(
                      color: kSlate,
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRecordTitle(context.l10n, record),
                    style: const TextStyle(
                      color: kBrandBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (record.glucoseValue != null)
                    _buildHighlightBox(
                      icon: LucideIcons.droplet,
                      boxColor: kBrandWarn,
                      label: context.l10n.kindGlucose,
                      value: '${record.glucoseValue}',
                      unit: 'mg/dL',
                    ),
                  if (record.insulinDose != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildHighlightBox(
                        icon: LucideIcons.syringe,
                        boxColor: kBrandBlue,
                        label: context.l10n.kindInsulin,
                        value: '${record.insulinDose}',
                        unit: 'IU',
                      ),
                    ),
                  if (record.foodAmountG != null ||
                      (record.foodBrand != null &&
                          record.foodBrand!.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildHighlightBox(
                        icon: LucideIcons.bone,
                        boxColor: kWarmCoral,
                        label: context.l10n.rowFood,
                        value: [
                          if (record.foodBrand != null &&
                              record.foodBrand!.isNotEmpty)
                            record.foodBrand,
                          if (record.foodAmountG != null)
                            '${record.foodAmountG}g',
                        ].join(' '),
                        unit: '',
                      ),
                    ),
                  if (record.weightKg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildHighlightBox(
                        icon: LucideIcons.activity,
                        boxColor: kCharcoal,
                        label: context.l10n.kindWeight,
                        value: '${record.weightKg}',
                        unit: 'kg',
                      ),
                    ),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        record.notes!,
                        style: const TextStyle(color: kSlate, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
