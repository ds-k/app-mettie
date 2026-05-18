import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dashboard_view.dart';
import 'ai_coach_view.dart';
import 'pet_management_view.dart';
import 'profile_view.dart';
import '../../core/constants/app_colors.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: kCanvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '기록 추가',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Center(child: Text('기록 입력 폼 준비 중...')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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
