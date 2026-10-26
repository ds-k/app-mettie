import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_error.dart';
import '../models/pet.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(Supabase.instance.client);
});

class PetRepository {
  final SupabaseClient _client;

  PetRepository(this._client);

  Future<List<Pet>> getPets() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('pets')
        .select('''
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
    final response = await _client
        .from('pets')
        .select()
        .eq('id', id)
        .maybeSingle();
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
    final response = await _client
        .from('pets')
        .update(data)
        .eq('id', pet.id)
        .select()
        .single();
    return Pet.fromJson(response);
  }

  Future<void> deletePet(String id) async {
    // cascade on delete will handle records and other tables if configured properly.
    await _client.from('pets').delete().eq('id', id);
  }

  Future<void> leaveFamily(String familyId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('user_families')
        .delete()
        .eq('family_id', familyId)
        .eq('user_id', userId);
  }

  Future<String> createInvitationCode(String familyId) async {
    // 1. 6자리 영문대문자/숫자 조합 코드 생성
    final random = math.Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    try {
      // 2. invitations 테이블에 저장 (24시간 만료)
      await _client.from('invitations').insert({
        'code': code,
        'family_id': familyId,
        'created_by': _client.auth.currentUser!.id,
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      });

      return code;
    } catch (e) {
      throw AppException(AppErrorCode.inviteCreateFailed, e);
    }
  }

  Future<void> joinFamilyWithCode(String code) async {
    try {
      // 보안을 위해 프론트엔드에서 직접 INSERT하지 않고 DB의 검증 함수(RPC)를 호출합니다.
      await _client.rpc('join_family_with_code', params: {'invite_code': code});
    } on PostgrestException catch (e) {
      // DB 함수 join_family_with_code가 RAISE하는 한국어 메시지로 구분한다
      if (e.message.contains('유효하지 않은')) {
        throw AppException(AppErrorCode.inviteInvalid, e);
      } else if (e.message.contains('만료된')) {
        throw AppException(AppErrorCode.inviteExpired, e);
      } else if (e.message.contains('이미 연결된')) {
        throw AppException(AppErrorCode.inviteAlreadyJoined, e);
      }
      throw AppException(AppErrorCode.joinFailed, e);
    } catch (e) {
      throw AppException(AppErrorCode.joinFailed, e);
    }
  }
}
