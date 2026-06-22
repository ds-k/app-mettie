import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/record.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(Supabase.instance.client);
});

class RecordRepository {
  final SupabaseClient _client;

  RecordRepository(this._client);

  Stream<List<Record>> watchRecords(String petId) {
    return _client
        .from('records')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .order('recorded_at')
        .map((events) => events.map((json) => Record.fromJson(json)).toList());
  }

  Future<Record> createRecord(Record record) async {
    final data = record.toJson();
    data.remove('id'); // ID is auto-generated
    
    final response = await _client.from('records').insert(data).select().single();
    return Record.fromJson(response);
  }

  Future<Record> updateRecord(Record record) async {
    final data = record.toJson();
    final response = await _client.from('records').update(data).eq('id', record.id).select().single();
    return Record.fromJson(response);
  }

  Future<void> deleteRecord(String id) async {
    final response = await _client.from('records').delete().eq('id', id).select();
    if (response.isEmpty) {
      throw Exception('기록을 찾을 수 없거나 삭제할 권한이 없습니다.');
    }
  }
  
  // 혈당 알람 조건 판별 로직
  // < 80: 저혈당 위험 (Red)
  // > targetGlucoseMax: 고혈당 위험 (Orange)
  // None: 정상/안전
  String? evaluateGlucoseAlarm(int? glucoseValue, int? targetGlucoseMax) {
    if (glucoseValue == null) return null;
    
    if (glucoseValue < 80) {
      return 'hypoglycemia';
    }
    
    if (targetGlucoseMax != null && glucoseValue > targetGlucoseMax) {
      return 'hyperglycemia';
    }
    
    return null;
  }
}
