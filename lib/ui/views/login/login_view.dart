import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 24.0,
                        ),
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
                                  context.l10n.loginHeadline,
                                  textAlign: TextAlign.center,
                                  style: kHeading2.copyWith(
                                    color: kBrandBlueDeep,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Image.asset(
                                  'assets/icons/mettie_logo.png',
                                  height: 80,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Mettie',
                                  textAlign: TextAlign.center,
                                  style: kDisplay.copyWith(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: kInk,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  context.l10n.loginSubtitle,
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
                                  icon: const Icon(
                                    LucideIcons.mail,
                                    color: kOnDark,
                                  ),
                                  label: Text(context.l10n.loginWithEmail),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    backgroundColor: kBrandBlue,
                                    foregroundColor: kOnDark,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // 디바이더 ("또는 소셜 계정으로 로그인")
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(color: kHairline),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Text(
                                        context.l10n.loginOr,
                                        style: kCaption.copyWith(color: kSlate),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(color: kHairline),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 2. Apple로 계속하기 버튼
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await ref
                                        .read(authRepositoryProvider)
                                        .signInWithApple();
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/icons/apple_logo.svg',
                                    width: 22,
                                    height: 22,
                                    colorFilter: const ColorFilter.mode(
                                      kOnDark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  label: Text(context.l10n.loginWithApple),
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
                                    await ref
                                        .read(authRepositoryProvider)
                                        .signInWithGoogle();
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/icons/google_logo.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  label: Text(context.l10n.loginWithGoogle),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
