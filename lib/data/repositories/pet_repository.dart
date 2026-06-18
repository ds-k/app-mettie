import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(Supabase.instance.client);
});

class PetRepository {
  final SupabaseClient _client;

  PetRepository(this._client);

  Future<List<Pet>> getPets() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client.from('pets').select('''
      *,
      families!inner (
        user_families!inner (
          role
        )
      )
    ''')
    .eq('families.user_families.user_id', userId)
    .order('created_at');
    
    return response.map((json) => Pet.fromJson(json)).toList();
  }

  Future<Pet?> getPet(String id) async {
    final response = await _client.from('pets').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Pet.fromJson(response);
  }

  Future<Pet> createPet(Pet pet) async {
    final data = pet.toJson();
    // Supabase will generate ID, created_at, updated_at
    data.remove('id');
    
    final response = await _client.from('pets').insert(data).select().single();
    return Pet.fromJson(response);
  }

  Future<Pet> updatePet(Pet pet) async {
    final data = pet.toJson();
    final response = await _client.from('pets').update(data).eq('id', pet.id).select().single();
    return Pet.fromJson(response);
  }

  Future<void> deletePet(String id) async {
    // cascade on delete will handle records and other tables if configured properly.
    await _client.from('pets').delete().eq('id', id);
  }

  Future<void> leaveFamily(String familyId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('user_families')
      .delete()
      .eq('family_id', familyId)
      .eq('user_id', userId);
  }

  Future<String> createInvitationCode(String familyId) async {
    // 1. 6자리 영문대문자/숫자 조합 코드 생성
    final random = math.Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      
    try {
      // 2. invitations 테이블에 저장 (24시간 만료)
      await _client.from('invitations').insert({
        'code': code,
        'family_id': familyId,
        'created_by': _client.auth.currentUser!.id,
        'expires_at': DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
      });
      
      return code;
    } on PostgrestException catch (e) {
      throw '초대 코드 생성 중 데이터베이스 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      throw '초대 코드를 생성할 수 없습니다. 네트워크를 확인해주세요.';
    }
  }

  Future<void> joinFamilyWithCode(String code) async {
    try {
      // 보안을 위해 프론트엔드에서 직접 INSERT하지 않고 DB의 검증 함수(RPC)를 호출합니다.
      await _client.rpc('join_family_with_code', params: {'invite_code': code});
    } on PostgrestException catch (e) {
      if (e.message.contains('유효하지 않은')) {
        throw '유효하지 않은 초대 코드입니다.';
      } else if (e.message.contains('만료된')) {
        throw '만료된 초대 코드입니다.';
      } else if (e.message.contains('이미 연결된')) {
        throw '이미 연결된 가족입니다.';
      }
      throw '가족 참여 처리 중 오류가 발생했습니다.';
    } catch (e) {
      throw '가족 참여에 실패했습니다. 네트워크를 확인해주세요.';
    }
  }
}
