import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 서버 함수 호출에 쓸 클라이언트. 로컬 개발에서는 별도 주소의 함수로 바꿔 끼울 수 있다.
final aiFunctionsProvider = Provider<FunctionsClient>((ref) => Supabase.instance.client.functions);

final aiCoachRepositoryProvider = Provider<AiCoachRepository>((ref) {
  return AiCoachRepository(Supabase.instance.client, ref.watch(aiFunctionsProvider));
});

class AiQuota {
  final int used;
  final int limit;
  final bool consented;

  const AiQuota({required this.used, required this.limit, required this.consented});

  int get remaining => (limit - used).clamp(0, limit);
}

class AiRef {
  final String recordId;
  final DateTime recordedAt;

  const AiRef(this.recordId, this.recordedAt);
}

/// 서버 함수(ai-coach)의 SSE 이벤트
sealed class AiEvent {}

class AiMeta extends AiEvent {
  final int used, limit, records;
  AiMeta(this.used, this.limit, this.records);
}

class AiDelta extends AiEvent {
  final String text;
  AiDelta(this.text);
}

class AiRefs extends AiEvent {
  final List<AiRef> refs;
  AiRefs(this.refs);
}

class AiDone extends AiEvent {}

/// 스트림 도중 실패: refused(안전 정책으로 답변 불가) | model_error
class AiStreamError extends AiEvent {
  final String code;
  AiStreamError(this.code);
}

/// 스트림 시작 전 실패: consent_required | quota_exceeded | pet_not_found | ai_unavailable | network
class AiCoachException implements Exception {
  final String code;
  final int? used;
  final int? limit;

  const AiCoachException(this.code, {this.used, this.limit});

  @override
  String toString() => 'AiCoachException($code)';
}

class AiCoachRepository {
  final SupabaseClient _client;
  final FunctionsClient _functions;

  AiCoachRepository(this._client, this._functions);

  /// 하루 기준은 기기의 UTC 오프셋(분)으로 자른다
  int get _offsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  Future<AiQuota> quota() async {
    final row = await _client.rpc('ai_quota_status', params: {'p_offset_minutes': _offsetMinutes}).single();
    return AiQuota(
      used: row['used'] as int,
      limit: row['daily_limit'] as int,
      consented: row['consented'] as bool? ?? false,
    );
  }

  Future<void> setConsent(bool consent) async {
    await _client.rpc('set_ai_consent', params: {'p_consent': consent});
  }

  /// 질문을 보내고 답변을 이벤트로 받는다. [history]는 user로 시작하고 끝나며 번갈아 나와야 한다.
  Stream<AiEvent> ask({
    required String petId,
    required List<({String role, String content})> history,
    required String locale,
  }) async* {
    final FunctionResponse res;
    try {
      // 함수가 바뀐 세션 토큰을 쓰도록 매번 넘긴다
      final token = _client.auth.currentSession?.accessToken;
      res = await _functions.invoke(
        'ai-coach',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        body: {
          'pet_id': petId,
          'messages': [for (final m in history) {'role': m.role, 'content': m.content}],
          'locale': locale,
          'utc_offset_minutes': _offsetMinutes,
        },
      );
    } on FunctionException catch (e) {
      final details = e.details is Map ? e.details as Map : const {};
      throw AiCoachException(
        details['error'] as String? ?? (e.status >= 500 ? 'ai_unavailable' : 'network'),
        used: details['used'] as int?,
        limit: details['limit'] as int?,
      );
    } catch (_) {
      throw const AiCoachException('network');
    }

    final data = res.data;
    if (data is! Stream<List<int>>) throw const AiCoachException('network');

    await for (final line in data.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter())) {
      if (!line.startsWith('data: ')) continue;
      final Map<String, dynamic> e;
      try {
        e = jsonDecode(line.substring(6)) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      switch (e['type']) {
        case 'meta':
          yield AiMeta(e['used'] as int, e['limit'] as int, e['records'] as int);
        case 'delta':
          yield AiDelta(e['text'] as String);
        case 'refs':
          yield AiRefs([
            for (final r in e['refs'] as List)
              AiRef(r['id'] as String, DateTime.parse(r['recorded_at'] as String).toLocal()),
          ]);
        case 'done':
          yield AiDone();
        case 'error':
          yield AiStreamError(e['code'] as String? ?? 'model_error');
      }
    }
  }
}
