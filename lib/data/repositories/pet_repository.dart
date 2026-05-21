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
}
