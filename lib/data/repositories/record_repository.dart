import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/record.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(Supabase.instance.client);
});

/// 실시간 구독으로 받아 오는 펫별 최근 기록 수. 추이 화면의 최대 기간(30일)을 넉넉히 덮는다.
const int kRecentRecordLimit = 500;

/// 서버 트리거 guard_duplicate_dose가 같은 회차의 두 번째 투여를 거부했을 때.
class DuplicateDoseException implements Exception {
  final String writerName;
  final DateTime recordedAt;
  final double? insulinDose;

  const DuplicateDoseException({
    required this.writerName,
    required this.recordedAt,
    this.insulinDose,
  });

  static DuplicateDoseException? tryParse(PostgrestException e) {
    if (e.message != 'DUPLICATE_DOSE') return null;
    try {
      final detail = jsonDecode(e.details as String) as Map<String, dynamic>;
      return DuplicateDoseException(
        writerName: detail['writer'] as String? ?? '가족',
        recordedAt: DateTime.parse(detail['recorded_at'] as String).toLocal(),
        insulinDose: (detail['insulin_dose'] as num?)?.toDouble(),
      );
    } catch (_) {
      return DuplicateDoseException(writerName: '가족', recordedAt: DateTime.now());
    }
  }
}

class RecordRepository {
  final SupabaseClient _client;

  RecordRepository(this._client);

  /// 펫의 최근 기록을 최신순으로 실시간 구독한다.
  Stream<List<Record>> watchRecords(String petId) {
    return _client
        .from('records')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .order('recorded_at', ascending: false)
        .limit(kRecentRecordLimit)
        .map((events) => events.map((json) => Record.fromJson(json)).toList());
  }

  Future<Record> createRecord(Record record) async {
    final created = await createRecords([record]);
    return created.single;
  }

  /// 한 번의 INSERT로 저장한다. 한 건이라도 거부되면 전부 저장되지 않는다.
  Future<List<Record>> createRecords(List<Record> records) async {
    final rows = records.map((r) => r.toJson()..remove('id')).toList();
    try {
      final response = await _client.from('records').insert(rows).select();
      return response.map((json) => Record.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DuplicateDoseException.tryParse(e) ?? e;
    }
  }

  Future<Record> updateRecord(Record record) async {
    final data = record.toJson();
    try {
      final response = await _client.from('records').update(data).eq('id', record.id).select().single();
      return Record.fromJson(response);
    } on PostgrestException catch (e) {
      throw DuplicateDoseException.tryParse(e) ?? e;
    }
  }

  Future<void> deleteRecord(String id) async {
    final response = await _client.from('records').delete().eq('id', id).select();
    if (response.isEmpty) {
      throw Exception('기록을 찾을 수 없거나 삭제할 권한이 없습니다.');
    }
  }

  /// 같은 가족 구성원의 표시 이름 (user_id → 이름).
  Future<Map<String, String>> fetchFamilyMembers(String familyId) async {
    final rows = await _client.rpc('family_members', params: {'p_family_id': familyId}) as List;
    return {
      for (final r in rows) r['user_id'] as String: r['display_name'] as String,
    };
  }
}
