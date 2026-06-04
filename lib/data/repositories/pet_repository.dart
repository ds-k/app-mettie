import 'dart:math' as _math;
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
    final response = await _client.from('pets').select().order('created_at');
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
    await _client.from('pets').delete().eq('id', id);
  }

  Future<String> createInvitationCode(String familyId) async {
    // 1. 6자리 영문대문자/숫자 조합 코드 생성
    final random = _math.Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      
    // 2. invitations 테이블에 저장 (24시간 만료)
    await _client.from('invitations').insert({
      'code': code,
      'family_id': familyId,
      'created_by': _client.auth.currentUser!.id,
      'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    });
    
    return code;
  }

  Future<void> joinFamilyWithCode(String code) async {
    // 1. 코드 조회
    final response = await _client
        .from('invitations')
        .select('family_id, expires_at')
        .eq('code', code)
        .maybeSingle();
        
    if (response == null) {
      throw '유효하지 않은 초대 코드입니다.';
    }
    
    final expiresAt = DateTime.parse(response['expires_at'] as String);
    if (expiresAt.isBefore(DateTime.now())) {
      throw '만료된 초대 코드입니다.';
    }
    
    final familyId = response['family_id'] as String;
    final userId = _client.auth.currentUser!.id;
    
    // 이미 소속된 가족인지 확인
    final existing = await _client
        .from('user_families')
        .select()
        .eq('user_id', userId)
        .eq('family_id', familyId)
        .maybeSingle();
        
    if (existing != null) {
      throw '이미 연결된 가족입니다.';
    }
    
    // 2. user_families에 조인
    await _client.from('user_families').insert({
      'user_id': userId,
      'family_id': familyId,
      'role': 'partner'
    });
  }
}
