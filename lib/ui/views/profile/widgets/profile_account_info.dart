import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../widgets/glass_card.dart';

class ProfileAccountInfo extends ConsumerWidget {
  const ProfileAccountInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '계정 정보',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kCharcoal,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: kBrandBlue,
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
      ],
    );
  }
}
