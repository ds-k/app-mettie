import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/record.dart';
import '../../../../data/repositories/record_repository.dart';

class DashboardRecordRow extends ConsumerWidget {
  final Record record;

  const DashboardRecordRow({super.key, required this.record});

  String _getRecordTitle(Record record) {
    final hour = record.recordedAt.hour;
    String timeStr = '기타';
    if (hour >= 5 && hour < 11) {
      timeStr = '아침';
    } else if (hour >= 11 && hour < 16) {
      timeStr = '점심';
    } else if (hour >= 16 && hour < 22) {
      timeStr = '저녁';
    } else {
      timeStr = '야간';
    }

    if (record.glucoseType == 'pre_meal') return '$timeStr 식전';
    if (record.glucoseType == 'post_meal') return '$timeStr 식후';
    if (record.glucoseType == 'fasting') return '공복';
    if (record.glucoseType == 'nadir') return '최저 혈당(Nadir)';

    if (record.insulinDose != null && record.glucoseValue == null) {
      return '$timeStr 인슐린';
    }
    if (record.foodAmountG != null && record.glucoseValue == null) {
      return '$timeStr 식사';
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
            title: const Text('기록 삭제'),
            content: const Text('이 기록을 정말 삭제하시겠습니까?\n삭제된 기록은 다시 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소', style: TextStyle(color: kSlate)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('삭제', style: TextStyle(color: kBrandError)),
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
            ).showSnackBar(const SnackBar(content: Text('기록이 삭제되었습니다.')));
          }
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')));
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
                    _getRecordTitle(record),
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
                      label: '혈당',
                      value: '${record.glucoseValue}',
                      unit: 'mg/dL',
                    ),
                  if (record.insulinDose != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildHighlightBox(
                        icon: LucideIcons.syringe,
                        boxColor: kBrandBlue,
                        label: '인슐린',
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
                        label: '사료',
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
                        label: '체중',
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
