import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../ui/views/splash_view.dart';
import '../../ui/views/login_view.dart';
import '../../ui/views/email_login_view.dart';
import '../../ui/views/home_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading || !authState.hasValue) return null;

      final isAuth = authState.value?.session != null;
      final location = state.matchedLocation;

      if (location == '/splash') return null;

      // 미인증 상태에서 /login 또는 /login/email이 아닌 다른 경로에 접속할 때만 /login으로 리다이렉트
      if (!isAuth && location != '/login' && location != '/login/email') {
        return '/login';
      }

      // 인증 완료 상태에서 로그인 관련 화면에 있으면 홈으로 이동
      if (isAuth && (location == '/login' || location == '/login/email')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashView()),
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
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
    ],
  );
});
