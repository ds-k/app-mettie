import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../view_models/splash_view_model.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // 초기화 트리거
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(splashViewModelProvider.notifier).initializeApp();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상태 구독 (사용하지 않는 변수 제거)

    // 완료 시 라우팅
    ref.listen<SplashState>(splashViewModelProvider, (previous, next) {
      if (next.status == SplashStatus.complete) {
        if (next.isAuth) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    });

    final splash = ref.watch(splashViewModelProvider);
    if (splash.status == SplashStatus.updateRequired) {
      return _UpdateRequired(storeUrl: splash.storeUrl);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: kHeroSkyFrom),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icons/mettie_logo.png', width: 140),
                const SizedBox(height: 24),
                Text(
                  'Mettie',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: kBrandBlueDeep,
                    fontWeight: FontWeight.w900,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kBrandBlue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 최소 지원 버전보다 낮을 때 앱 사용을 막는 화면.
class _UpdateRequired extends StatelessWidget {
  final String? storeUrl;
  const _UpdateRequired({required this.storeUrl});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: kHeroSkyFrom,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icons/mettie_logo.png', width: 96),
              const SizedBox(height: 28),
              Text(l.updateTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 12),
              Text(l.updateBody,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: kSlate, height: 1.5)),
              if (storeUrl?.isNotEmpty ?? false) ...[
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => launchUrl(Uri.parse(storeUrl!), mode: LaunchMode.externalApplication),
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrandBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l.updateButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
