import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../view_models/dashboard_view_model.dart';
import '../../view_models/pet_management_view_model.dart';
import 'widgets/dashboard_summary_stat.dart';
import 'widgets/dashboard_record_row.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/record.dart';
import 'widgets/pet_selector_bottom_sheet.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final recordsAsync = ref.watch(recordsStreamProvider);
    final pet = ref.watch(currentPetProvider);

    final petsAsync = ref.watch(petsProvider);

    // 로딩 상태 처리
    if (petsAsync.isLoading || (petsAsync.isRefreshing && !petsAsync.hasValue) || petsAsync.value == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: kBrandBlue)),
      );
    }

    // 빈 화면 (Empty State) 처리
    if (pet == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.cat, color: kStone, size: 64),
                const SizedBox(height: 24),
                const Text(
                  '아직 등록된 반려동물이 없어요.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '반려동물을 등록하고\n맞춤형 혈당 관리와 AI 코칭을 시작해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: kSlate, height: 1.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/pet-management');
                  },
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('새 반려동물 등록하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBlue,
                    foregroundColor: kOnDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const PetSelectorBottomSheet(),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${pet.name}의 대시보드',
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, color: kInk, size: 20),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final _ = ref.refresh(recordsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: kBrandBlue,
        child: CustomScrollView(
        slivers: [
          // 혈당 알람 배너
          if (state.activeAlarm != null)
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: state.activeAlarm == 'hypoglycemia'
                      ? kBrandError
                      : kBrandWarn,
                  borderRadius: BorderRadius.circular(kRadiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: state.activeAlarm == 'hypoglycemia'
                          ? kOnDark
                          : kInk,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.activeAlarm == 'hypoglycemia'
                            ? '저혈당 위험! 즉시 조치가 필요합니다.'
                            : '고혈당 경고! 목표 범위를 초과했습니다.',
                        style: TextStyle(
                          color: state.activeAlarm == 'hypoglycemia'
                              ? kOnDark
                              : kInk,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Hero Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kHeroDarkFrom, kHeroDarkTo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(kRadiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '최근 14일 혈당 요약',
                      style: TextStyle(color: kOnDark, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DashboardSummaryStat(
                          label: '평균',
                          value: state.avgGlucose?.round().toString() ?? '-',
                        ),
                        DashboardSummaryStat(
                          label: '최저',
                          value: state.nadirGlucose?.toString() ?? '-',
                        ),
                        DashboardSummaryStat(
                          label: '최고',
                          value: state.peakGlucose?.toString() ?? '-',
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.syringe,
                          color: kOnDark,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '마지막 인슐린: ${state.lastInsulinDose != null ? '${state.lastInsulinDose} IU' : '기록 없음'}',
                          style: const TextStyle(color: kOnDark, fontSize: 14),
                        ),
                        if (state.lastInsulinTime != null) ...[
                          const Spacer(),
                          Text(
                            _formatTimeAgo(state.lastInsulinTime!),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 타임라인 리스트
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '최근 기록',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kCharcoal,
                ),
              ),
            ),
          ),

          recordsAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        '아직 기록이 없습니다.\n아래 + 버튼을 눌러 기록을 추가해보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kSlate),
                      ),
                    ),
                  ),
                );
              }

              // 최신순 정렬
              final sortedRecords = List<Record>.from(records)
                ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

              final List<dynamic> flattenedItems = [];
              String? currentDateStr;

              for (final r in sortedRecords) {
                final dateStr = _formatDateHeader(r.recordedAt);
                if (dateStr != currentDateStr) {
                  flattenedItems.add(dateStr);
                  currentDateStr = dateStr;
                }
                flattenedItems.add(r);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = flattenedItems[index];
                  if (item is String) {
                    return _buildDateHeader(item);
                  } else if (item is Record) {
                    return Column(
                      children: [
                        DashboardRecordRow(record: item),
                        // 마지막 항목이 아니면서 다음 항목도 Record(같은 날짜)라면 구분선 추가
                        if (index < flattenedItems.length - 1 &&
                            flattenedItems[index + 1] is Record)
                          const Divider(height: 1, color: kHairline),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }, childCount: flattenedItems.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),

          // 하단 여백 (FAB를 가리지 않기 위해)
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final weekday = ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
    return '${DateFormat('yyyy. MM. dd.').format(date)} $weekday요일';
  }

  Widget _buildDateHeader(String dateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: kSurfaceSoft,
        border: Border(
          top: BorderSide(color: kHairline),
          bottom: BorderSide(color: kHairline),
        ),
      ),
      child: Text(
        dateStr,
        style: const TextStyle(
          color: kSlate,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}
