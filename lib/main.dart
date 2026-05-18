import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';

// ─── Supabase 설정 ─────────────────────────────────────────────────────────────
// TODO: Phase 1에서 실제 값으로 교체
const String _supabaseUrl = 'YOUR_SUPABASE_URL';
const String _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

// ─── 라우터 ────────────────────────────────────────────────────────────────────
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderView(label: 'Mettie'),
    ),
  ],
);

// ─── 진입점 ────────────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MettieApp(),
    ),
  );
}

// ─── 루트 위젯 ─────────────────────────────────────────────────────────────────
class MettieApp extends StatelessWidget {
  const MettieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mettie',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Phase 0 임시 화면 — Phase 1에서 삭제 ─────────────────────────────────────
class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }
}
