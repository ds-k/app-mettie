import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/repositories/auth_repository.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라데이션
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kHeroSkyFrom, kCanvas],
                stops: [0.0, 0.4],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ─── 상단 영역 (서비스 로고 & 소개 문구) ──────────────────────────
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 80),
                              Text(
                                '반려동물 대사질환 케어\n온디바이스 AI 솔루션',
                                textAlign: TextAlign.center,
                                style: kHeading2.copyWith(
                                  color: kBrandTealDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mettie',
                                textAlign: TextAlign.center,
                                style: kDisplay.copyWith(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  color: kInk,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '대사질환 분석부터 맞춤형 영양 케어까지\nMettie AI가 함께합니다.',
                                textAlign: TextAlign.center,
                                style: kBodyMd.copyWith(
                                  color: kSlate,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),

                          // ─── 하단 영역 (깔끔한 3개 버튼 구성) ──────────────────────────────
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. 이메일로 로그인 버튼
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.push('/login/email');
                                },
                                icon: const Icon(LucideIcons.mail, color: kOnDark),
                                label: const Text('이메일로 계속하기'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: kBrandTeal,
                                  foregroundColor: kOnDark,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 디바이더 ("또는 소셜 계정으로 로그인")
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: kHairline)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      '또는',
                                      style: kCaption.copyWith(color: kSlate),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: kHairline)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 2. Apple로 계속하기 버튼
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await ref.read(authRepositoryProvider).signInWithApple();
                                },
                                icon: const Icon(LucideIcons.apple, color: kOnDark),
                                label: const Text('Apple로 계속하기'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: kInk,
                                  foregroundColor: kOnDark,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 3. Google로 계속하기 버튼
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await ref.read(authRepositoryProvider).signInWithGoogle();
                                },
                                icon: const Icon(LucideIcons.mail, color: kCharcoal),
                                label: const Text('Google로 계속하기'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: kSurface,
                                  foregroundColor: kCharcoal,
                                  side: const BorderSide(color: kHairline),
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
