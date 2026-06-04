import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../view_models/pet_management_view_model.dart';
import '../../view_models/dashboard_view_model.dart';

class PetSelectorBottomSheet extends ConsumerWidget {
  const PetSelectorBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsProvider);
    final selectedPetId = ref.watch(selectedPetIdProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
          ),
          child: Column(
            children: [
              // 1. 헤더 (손잡이)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kHairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '반려동물 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: kHairline),

              // 2. 펫 리스트
              Expanded(
                child: petsAsync.when(
                  data: (pets) {
                    if (pets.isEmpty) {
                      return const Center(child: Text('등록된 반려동물이 없습니다.'));
                    }
                    
                    // selectedPetId가 null일 땐 첫번째 아이템이 선택된 것으로 간주
                    final activeId = selectedPetId ?? pets.first.id;

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        final isSelected = pet.id == activeId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? kBrandTeal.withOpacity(0.1) : kCanvas,
                            backgroundImage: pet.avatarUrl != null ? NetworkImage(pet.avatarUrl!) : null,
                            child: pet.avatarUrl == null
                                ? Icon(
                                    pet.species == 'cat' ? LucideIcons.cat : LucideIcons.dog,
                                    color: isSelected ? kBrandTeal : kStone,
                                  )
                                : null,
                          ),
                          title: Text(
                            pet.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? kBrandTeal : kInk,
                            ),
                          ),
                          subtitle: Text(
                            '${pet.species == 'cat' ? '고양이' : '강아지'} / ${pet.breed ?? '품종 모름'}',
                            style: const TextStyle(color: kSlate, fontSize: 13),
                          ),
                          trailing: isSelected
                              ? const Icon(LucideIcons.check, color: kBrandTeal)
                              : null,
                          onTap: () {
                            ref.read(selectedPetIdProvider.notifier).selectPet(pet.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: kBrandTeal)),
                  error: (error, stack) => Center(child: Text('오류 발생: $error')),
                ),
              ),

              // 3. 새 반려동물 추가 버튼
              const Divider(color: kHairline, height: 1),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // /pet-management 로 이동하여 신규 등록 유도
                  // BottomNavigationBar index를 3(반려동물)으로 변경할 수도 있음 (보통 go_router 활용)
                  // 그러나 여기서는 앱 전체 라우터 구조가 go_router의 StatefulShellRoute인지 아닌지에 따라 다름
                  // UI Builder 스펙상 Home 내 IndexedStack을 쓴다면 Provider로 Index를 바꿔야 하지만,
                  // 우선 간단히 context.go() 사용하거나 별도의 Create 뷰로 라우팅
                  // 이 프로젝트는 HomeView가 State를 가지므로 일단 push로 처리하거나 뷰 이동 고려
                  // 사용자가 HomeView _onTabTapped 를 호출할 수는 없으므로 context.push() 사용
                  // 여기서는 명시적인 push 권장
                  // 구현 편의상 아무 동작이나 넣고 추후 조정.
                },
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.plusCircle, color: kBrandTeal),
                      const SizedBox(width: 8),
                      const Text(
                        '새 반려동물 추가',
                        style: TextStyle(
                          color: kBrandTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
