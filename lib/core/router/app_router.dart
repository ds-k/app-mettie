import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../ui/views/splash/splash_view.dart';
import '../../ui/views/login/login_view.dart';
import '../../ui/views/login/email_login_view.dart';
import '../../ui/views/home/home_view.dart';
import '../../ui/views/today/today_view.dart';
import '../../ui/views/trends/trends_view.dart';
import '../../ui/views/ai_coach/ai_coach_view.dart';
import '../../ui/views/book/book_view.dart';
import '../../ui/views/pet_management/pet_management_view.dart';
import '../../ui/views/profile/profile_view.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorTodayKey = GlobalKey<NavigatorState>(debugLabel: 'todayShell');
final _shellNavigatorTrendsKey = GlobalKey<NavigatorState>(debugLabel: 'trendsShell');
final _shellNavigatorAiCoachKey = GlobalKey<NavigatorState>(debugLabel: 'aiCoachShell');
final _shellNavigatorBookKey = GlobalKey<NavigatorState>(debugLabel: 'bookShell');

final routerProvider = Provider<GoRouter>((ref) {
  // 인증 상태를 watch하면 토큰 갱신 같은 이벤트마다 GoRouter가 새로 만들어져 화면 전체가 다시 그려진다.
  // 라우터는 한 번만 만들고, 로그인 여부가 바뀔 때만 redirect를 다시 평가한다.
  final authRefresh = ValueNotifier<bool>(false);
  ref.listen<bool>(
    authStateProvider.select((s) => s.value?.session != null),
    (_, isAuth) => authRefresh.value = isAuth,
  );

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (!authState.hasValue) return null;

      final isAuth = authState.value?.session != null;
      final location = state.matchedLocation;

      if (location == '/splash') return null;

      // 미인증 상태에서 /login 또는 /login/email이 아닌 다른 경로에 접속할 때만 /login으로 리다이렉트
      if (!isAuth && location != '/login' && location != '/login/email' && location != '/login-callback') {
        return '/login';
      }

      // 인증 완료 상태에서 로그인 관련 화면에 있으면 홈으로 이동
      if (isAuth && (location == '/login' || location == '/login/email' || location == '/splash')) {
        return '/home/today';
      }
      
      if (isAuth && location == '/home') {
        return '/home/today';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash', 
        builder: (context, state) => const SplashView()
      ),
      GoRoute(
        path: '/login-callback',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
        routes: [
          GoRoute(
            path: 'email',
            builder: (context, state) => const EmailLoginView(),
          ),
        ],
      ),
      // 계정·알림 설정은 건강수첩 등 각 탭 상단의 톱니에서 연다
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileView(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeView(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTodayKey,
            routes: [
              GoRoute(path: '/home/today', builder: (context, state) => const TodayView()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTrendsKey,
            routes: [
              GoRoute(path: '/home/trends', builder: (context, state) => const TrendsView()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAiCoachKey,
            routes: [
              GoRoute(path: '/home/ai-coach', builder: (context, state) => const AiCoachView()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBookKey,
            routes: [
              GoRoute(
                path: '/home/book',
                builder: (context, state) => const BookView(),
                routes: [
                  GoRoute(path: 'pets', builder: (context, state) => const PetManagementView()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authRefresh.dispose();
  });

  return router;
});
