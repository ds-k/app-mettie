import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/pet.dart';
import '../../../widgets/glass_card.dart';
import '../../../view_models/profile_view_model.dart';

class PetListItem extends ConsumerWidget {
  final Pet pet;
  final VoidCallback onDeleteOrLeave;

  const PetListItem({
    super.key,
    required this.pet,
    required this.onDeleteOrLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = pet.role == 'owner';

    return GlassCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: kBrandBlue.withValues(alpha: 0.1),
              backgroundImage: pet.avatarUrl != null
                  ? NetworkImage(pet.avatarUrl!)
                  : null,
              child: pet.avatarUrl == null
                  ? Icon(
                      pet.species == 'cat' ? LucideIcons.cat : LucideIcons.dog,
                      color: kBrandBlue,
                    )
                  : null,
            ),
            title: Row(
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOwner
                        ? kBrandBlue.withValues(alpha: 0.1)
                        : kStone.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOwner ? '보호자' : '공동양육자',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOwner ? kBrandBlue : kStone,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              "${pet.species == 'cat' ? '고양이' : '강아지'} / ${pet.breed ?? '품종 모름'}",
            ),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2, color: kBrandError),
              onPressed: onDeleteOrLeave,
              tooltip: isOwner ? '삭제' : '나가기',
            ),
          ),
          const Divider(height: 1, color: kHairline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '가족 공유',
                  style: TextStyle(
                    color: kCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: const Text('초대 코드 발급'),
                  style: TextButton.styleFrom(
                    foregroundColor: kBrandBlue,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final profileVm = ref.read(
                      profileViewModelProvider.notifier,
                    );
                    await profileVm.createInvitation(pet.familyId);
                    final code = ref
                        .read(profileViewModelProvider)
                        .generatedCode;
                    if (code != null && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('초대 코드'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '아래 코드를 복사하여 가족에게 전달하세요.\n코드는 24시간 동안 유효합니다.',
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: kSurfaceSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                '닫기',
                                style: TextStyle(color: kSlate),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(LucideIcons.copy, size: 18),
                              label: const Text('복사하기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBrandBlue,
                                foregroundColor: kOnDark,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('초대 코드가 복사되었습니다.'),
                                  ),
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
