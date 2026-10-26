import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/labels.dart';
import '../../../view_models/pet_management_view_model.dart';
import '../../../view_models/dashboard_view_model.dart';

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
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(kRadiusLg),
            ),
          ),
          child: Column(
            children: [
              // 1. 헤더 (손잡이)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 8,
                  bottom: 20,
                ),
                child: Row(
                  children: [
                    Text(
                      context.l10n.selectorTitle,
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
                      return Center(child: Text(context.l10n.selectorEmpty));
                    }

                    // selectedPetId가 null일 땐 첫번째 아이템이 선택된 것으로 간주
                    final activeId = selectedPetId ?? pets.first.id;

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        final isSelected = pet.id == activeId;
                        final isOwner = pet.role == 'owner';

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? kBrandBlue.withValues(alpha: 0.1)
                                  : kCanvas,
                              backgroundImage: pet.avatarUrl != null
                                  ? NetworkImage(pet.avatarUrl!)
                                  : null,
                              child: pet.avatarUrl == null
                                  ? Icon(
                                      pet.species == 'cat'
                                          ? LucideIcons.cat
                                          : LucideIcons.dog,
                                      color: isSelected ? kBrandBlue : kStone,
                                    )
                                  : null,
                            ),
                            title: Text(
                              pet.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? kBrandBlue : kInk,
                              ),
                            ),
                            subtitle: Text(
                              '${pet.species == 'cat' ? context.l10n.speciesCat : context.l10n.speciesDog} / ${pet.breed ?? context.l10n.breedUnknown}',
                              style: const TextStyle(
                                color: kSlate,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  const Icon(
                                    LucideIcons.check,
                                    color: kBrandBlue,
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    LucideIcons.moreVertical,
                                    color: kStone,
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final title = isOwner
                                          ? context.l10n.petDeleteTitle
                                          : context.l10n.petLeaveTitle;
                                      final content = isOwner
                                          ? context.l10n.petDeleteBody(pet.name)
                                          : context.l10n.petLeaveBody(pet.name);

                                      final notifier = ref.read(
                                        petManagementViewModelProvider.notifier,
                                      );

                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(title),
                                          content: Text(content),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: Text(
                                                context.l10n.commonCancel,
                                                style: TextStyle(color: kSlate),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: Text(
                                                isOwner ? context.l10n.commonDelete : context.l10n.petLeave,
                                                style: const TextStyle(
                                                  color: kBrandError,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await notifier.deletePetOrLeave(pet);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        isOwner ? context.l10n.selectorDeleteAction : context.l10n.petLeave,
                                        style: const TextStyle(
                                          color: kBrandError,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              ref
                                  .read(selectedPetIdProvider.notifier)
                                  .selectPet(pet.id);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: kBrandBlue),
                  ),
                  error: (error, stack) => Center(child: Text(errorMessage(context.l10n, error))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
