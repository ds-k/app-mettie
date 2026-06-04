import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../view_models/dashboard_view_model.dart';
import '../view_models/profile_view_model.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
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
          title: const Text('가족 참여하기'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('전달받은 6자리 초대 코드를 입력하세요.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '초대 코드',
                    counterText: '',
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return '6자리 코드를 입력해주세요.';
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
              child: const Text('취소', style: TextStyle(color: kSlate)),
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
                if (success && mounted) {
                  Navigator.pop(context);
                  _joinCodeController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가족에 성공적으로 참여했습니다.')),
                  );
                } else if (mounted) {
                  final error = ref.read(profileViewModelProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? '참여에 실패했습니다.'),
                      backgroundColor: kBrandError,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandTeal,
                foregroundColor: kOnDark,
                shape: const StadiumBorder(),
              ),
              child: const Text('참여'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final currentPet = ref.watch(currentPetProvider);
    final profileState = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text(
          '프로필',
          style: TextStyle(color: kInk, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 계정 정보 섹션
            const Text(
              '계정 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kCharcoal,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCanvas,
                borderRadius: BorderRadius.circular(kRadiusMd),
                border: Border.all(color: kHairline),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: kBrandTeal,
                    child: Icon(LucideIcons.user, color: kOnDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.userMetadata?['full_name'] ?? '사용자',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kInk,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: kSlate, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.logOut, color: kSlate),
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    tooltip: '로그아웃',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 가족 관리 섹션
            const Text(
              '가족 관리 (공동 양육자)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '반려동물 데이터를 가족과 함께 실시간으로 공유하고 관리하세요.',
              style: TextStyle(color: kSlate, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 가족 초대하기 (코드 발급)
            if (currentPet != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCanvas,
                  borderRadius: BorderRadius.circular(kRadiusMd),
                  border: Border.all(color: kHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.userPlus, color: kBrandTeal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '가족 초대하기',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '현재 선택된 반려동물(${currentPet.name})의 공간에 파트너를 초대합니다. 생성된 코드는 24시간 동안 유효합니다.',
                      style: const TextStyle(color: kSlate, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (profileState.generatedCode != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBrandTeal.withOpacity(0.1),
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
                                color: kBrandTeal,
                                letterSpacing: 4,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.copy,
                                color: kBrandTeal,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: profileState.generatedCode!,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('초대 코드가 복사되었습니다.'),
                                  ),
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
                            backgroundColor: kBrandTeal,
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
                              : const Text('초대 코드 발급받기'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 가족 참여하기 (코드 입력)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCanvas,
                borderRadius: BorderRadius.circular(kRadiusMd),
                border: Border.all(color: kHairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.users, color: kCharcoal, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '가족 참여하기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '가족에게 전달받은 6자리 초대 코드가 있다면 아래 버튼을 눌러 입력하세요.',
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
                      child: const Text('초대 코드 입력'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
