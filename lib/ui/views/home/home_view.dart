import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'widgets/record_entry_bottom_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../view_models/pet_management_view_model.dart';

class HomeView extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeView({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _showRecordEntryBottomSheet() {
    final petsAsync = ref.read(petsProvider);
    if (petsAsync.value?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록을 추가하려면 먼저 반려동물을 등록해주세요.')),
      );
      _onTabTapped(2);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const RecordEntryBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petsProvider);

    // 에러 발생 시
    if (petsAsync.hasError) {
      return Scaffold(
        backgroundColor: kSurface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: kBrandError,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  '데이터를 불러오지 못했습니다.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  petsAsync.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kSlate),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(petsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBlue,
                    foregroundColor: kOnDark,
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 로딩 중
    if (petsAsync.isLoading || (petsAsync.isRefreshing && !petsAsync.hasValue) || petsAsync.value == null) {
      return const Scaffold(
        backgroundColor: kSurface,
        body: Center(child: CircularProgressIndicator(color: kBrandBlue)),
      );
    }

    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // 상태표시줄 아이콘 검정색(어두운 색)으로 변경
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kHeroSkyFrom, kHeroSkyTo],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true, // 바텀 네비게이션이 콘텐츠 위에 플로팅되도록 true 설정
          body: widget.navigationShell,
          bottomNavigationBar: isKeyboardOpen
              ? null
              : SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNavItem(0, LucideIcons.layoutDashboard), // 대시보드
                              _buildNavItem(1, LucideIcons.sparkle), // AI 코칭
                              _buildAddButton(),
                              _buildNavItem(2, LucideIcons.pawPrint), // 반려동물
                              _buildNavItem(3, LucideIcons.userCircle), // 프로필
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = widget.navigationShell.currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? kSlate.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(icon, color: isSelected ? kInk : kSlate, size: 26),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showRecordEntryBottomSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: kBrandBlue,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: kBrandBlue.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 26),
      ),
    );
  }
}
