import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../view_models/splash_view_model.dart';

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

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
    // 상태 구독
    final splashState = ref.watch(splashViewModelProvider);
    
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kHeroSkyFrom, kHeroSkyTo],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
