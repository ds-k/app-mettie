import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(Supabase.instance.client);
});

/// 서버의 앱 설정(app_config). 로그인 전에도 읽을 수 있다.
class AppConfigRepository {
  final SupabaseClient _client;

  AppConfigRepository(this._client);

  Future<Map<String, dynamic>> fetch() async {
    final rows = await _client.from('app_config').select('key, value') as List;
    return {for (final r in rows) r['key'] as String: r['value']};
  }
}
