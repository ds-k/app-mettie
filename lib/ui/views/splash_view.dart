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
                        color: kBrandTealDeep,
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                      ),
                ),
                const SizedBox(height: 16),
                
                if (splashState.status == SplashStatus.downloadingModel) ...[
                  const Text(
                    'AI 코칭 모델을 준비 중입니다...\n(최초 1회, 약 1.5GB 다운로드)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kBrandTealDeep,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Wi-Fi 환경에서의 다운로드를 권장합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kStone,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: splashState.downloadProgress > 0 
                               ? splashState.downloadProgress / 100 
                               : null, // 진행률 0일 때는 애니메이션 표시
                        backgroundColor: kBrandTeal.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(kBrandTeal),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (splashState.downloadProgress > 0)
                    Text(
                      '${splashState.downloadProgress}%',
                      style: const TextStyle(
                        color: kBrandTealDeep,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [
                          FontFeature.tabularFigures()
                        ],
                      ),
                    ),
                ] else ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kBrandTeal),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
