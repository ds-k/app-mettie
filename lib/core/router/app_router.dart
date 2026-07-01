import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../ui/views/splash/splash_view.dart';
import '../../ui/views/login/login_view.dart';
import '../../ui/views/login/email_login_view.dart';
import '../../ui/views/home/home_view.dart';
import '../../ui/views/dashboard/dashboard_view.dart';
import '../../ui/views/ai_coach/ai_coach_view.dart';
import '../../ui/views/pet_management/pet_management_view.dart';
import '../../ui/views/profile/profile_view.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboardShell');
final _shellNavigatorAiCoachKey = GlobalKey<NavigatorState>(debugLabel: 'aiCoachShell');
final _shellNavigatorPetManagementKey = GlobalKey<NavigatorState>(debugLabel: 'petManagementShell');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profileShell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading || !authState.hasValue) return null;

      final isAuth = authState.value?.session != null;
      final location = state.matchedLocation;

      if (location == '/splash') return null;

      // 미인증 상태에서 /login 또는 /login/email이 아닌 다른 경로에 접속할 때만 /login으로 리다이렉트
      if (!isAuth && location != '/login' && location != '/login/email' && location != '/login-callback') {
        return '/login';
      }

      // 인증 완료 상태에서 로그인 관련 화면에 있으면 홈으로 이동
      if (isAuth && (location == '/login' || location == '/login/email' || location == '/splash')) {
        return '/home/dashboard';
      }
      
      if (isAuth && location == '/home') {
        return '/home/dashboard';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeView(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/home/dashboard',
                builder: (context, state) => const DashboardView(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAiCoachKey,
            routes: [
              GoRoute(
                path: '/home/ai-coach',
                builder: (context, state) => const AiCoachView(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPetManagementKey,
            routes: [
              GoRoute(
                path: '/home/pet-management',
                builder: (context, state) => const PetManagementView(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/home/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
