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

  // 뷰 인덱스 매핑 (FAB 위치인 2번은 제외하고 매핑)
  final List<Widget> _views = const [
    DashboardView(),
    AiCoachView(),
    SizedBox.shrink(), // Index 2 (FAB 자리 - 표시되지 않음)
    PetManagementView(),
    ProfileView(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      _showRecordEntryBottomSheet();
      return;
    }
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
                    backgroundColor: kBrandTeal,
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
        body: Center(child: CircularProgressIndicator(color: kBrandTeal)),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _views),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kBrandTeal,
        unselectedItemColor: kStone,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2), // chart_bar 유사
            label: '대시보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.sparkles), // auto_awesome 유사
            label: 'AI 코칭',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.plusCircle, size: 36, color: kBrandTeal),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.cat), // pets 유사
            label: '반려동물',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user), // person 유사
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
