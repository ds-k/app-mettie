import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/labels.dart';
import '../../../view_models/dashboard_view_model.dart';
import '../../../view_models/profile_view_model.dart';
import '../../../widgets/glass_card.dart';

class ProfileFamilyManagement extends ConsumerStatefulWidget {
  const ProfileFamilyManagement({super.key});

  @override
  ConsumerState<ProfileFamilyManagement> createState() =>
      _ProfileFamilyManagementState();
}

class _ProfileFamilyManagementState
    extends ConsumerState<ProfileFamilyManagement> {
  final _joinCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  void _showJoinFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.familyJoinTitle),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.familyJoinPrompt),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: context.l10n.familyInviteCodeLabel,
                    counterText: '',
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return context.l10n.familyCodeRequired;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _joinCodeController.clear();
                Navigator.pop(context);
              },
              child: Text(context.l10n.commonCancel, style: const TextStyle(color: kSlate)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  return;
                }

                final code = _joinCodeController.text.trim().toUpperCase();
                final success = await ref
                    .read(profileViewModelProvider.notifier)
                    .joinFamily(code);
                if (!context.mounted) return;

                if (success) {
                  Navigator.pop(context);
                  _joinCodeController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.familyJoined)),
                  );
                } else {
                  final error = ref.read(profileViewModelProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage(context.l10n, error)),
                      backgroundColor: kBrandError,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                foregroundColor: kOnDark,
                shape: const StadiumBorder(),
              ),
              child: Text(context.l10n.familyJoin),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPet = ref.watch(currentPetProvider);
    final profileState = ref.watch(profileViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.familyTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.familyIntro,
          style: TextStyle(color: kSlate, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // 가족 초대하기 (코드 발급)
        if (currentPet != null) ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.userPlus, color: kBrandBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      context.l10n.familyInviteTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.familyInviteBody(currentPet.name),
                  style: const TextStyle(color: kSlate, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (profileState.generatedCode != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBrandBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(kRadiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          profileState.generatedCode!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kBrandBlue,
                            letterSpacing: 4,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.copy, color: kBrandBlue),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: profileState.generatedCode!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.inviteCopied)),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: profileState.isLoading
                          ? null
                          : () => ref
                                .read(profileViewModelProvider.notifier)
                                .createInvitation(currentPet.familyId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandBlue,
                        foregroundColor: kOnDark,
                        shape: const StadiumBorder(),
                      ),
                      child: profileState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: kOnDark,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(context.l10n.familyGetCode),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 가족 참여하기 (코드 입력)
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.users, color: kCharcoal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    context.l10n.familyJoinTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, color: kInk),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.familyJoinBody,
                style: TextStyle(color: kSlate, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: profileState.isLoading
                      ? null
                      : _showJoinFamilyDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kCharcoal,
                    side: const BorderSide(color: kHairline),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(context.l10n.familyEnterCode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
