import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/l10n.dart';
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
                    isOwner ? context.l10n.roleOwner : context.l10n.roleCoCaregiver,
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
              "${pet.species == 'cat' ? context.l10n.speciesCat : context.l10n.speciesDog} / ${pet.breed ?? context.l10n.breedUnknown}",
            ),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2, color: kBrandError),
              onPressed: onDeleteOrLeave,
              tooltip: isOwner ? context.l10n.commonDelete : context.l10n.petLeave,
            ),
          ),
          const Divider(height: 1, color: kHairline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.familySharing,
                  style: TextStyle(
                    color: kCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: Text(context.l10n.inviteCreate),
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
                          title: Text(context.l10n.inviteCodeTitle),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.inviteCodeBody,
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
                              child: Text(
                                context.l10n.commonClose,
                                style: TextStyle(color: kSlate),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(LucideIcons.copy, size: 18),
                              label: Text(context.l10n.inviteCopy),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBrandBlue,
                                foregroundColor: kOnDark,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.inviteCopied),
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
