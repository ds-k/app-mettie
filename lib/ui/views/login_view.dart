import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kHeroSkyFrom, kCanvas],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Text(
                  '반려동물 대사질환 케어\n온디바이스 AI 솔루션',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: kBrandTealDeep,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mettie',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: kInk,
                        letterSpacing: -1,
                      ),
                ),
                const Spacer(flex: 3),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signInWithApple();
                  },
                  icon: const Icon(LucideIcons.apple),
                  label: const Text('Apple로 계속하기'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signInWithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSurface,
                    foregroundColor: kCharcoal,
                    side: const BorderSide(color: kHairline),
                  ),
                  icon: const Icon(LucideIcons.mail, color: kCharcoal), // 구글 로고 대안
                  label: const Text('Google로 계속하기'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
