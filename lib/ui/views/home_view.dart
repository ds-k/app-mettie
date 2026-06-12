import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dashboard_view.dart';
import 'ai_coach_view.dart';
import 'pet_management_view.dart';
import 'profile_view.dart';
import 'widgets/record_entry_bottom_sheet.dart';
import '../../core/constants/app_colors.dart';
import '../view_models/pet_management_view_model.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _currentIndex = 0;

  // 뷰 인덱스 매핑
  final List<Widget> _views = const [
    DashboardView(),
    AiCoachView(),
    PetManagementView(),
    ProfileView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showRecordEntryBottomSheet() {
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

    // 강제 리다이렉트를 제거하고, 메인 UI를 항상 렌더링합니다. (Empty State 처리는 개별 뷰에서 담당)

    // 로딩 중
    if (petsAsync.isLoading) {
      return const Scaffold(
        backgroundColor: kSurface,
        body: Center(child: CircularProgressIndicator(color: kBrandBlue)),
      );
    }

    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kHeroSkyFrom, kHeroSkyTo],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // 바텀 네비게이션 아래로 배경이 들어가도록
        body: IndexedStack(index: _currentIndex, children: _views),
        bottomNavigationBar: isKeyboardOpen
            ? null
            : SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(0, LucideIcons.layoutDashboard, '대시보드'),
                            _buildNavItem(1, LucideIcons.bot, 'AI 코칭'),
                            _buildAddButton(),
                            _buildNavItem(2, LucideIcons.pawPrint, '반려동물'),
                            _buildNavItem(3, LucideIcons.userCircle, '프로필'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kBrandBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? kBrandBlue : kStone,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? kBrandBlue : kStone,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showRecordEntryBottomSheet,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: kBrandBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.plus,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
