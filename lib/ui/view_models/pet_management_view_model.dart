import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/constants/veterinary_guidelines.dart';
import '../../data/models/pet.dart';
import '../../data/repositories/pet_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'dashboard_view_model.dart';

final petsProvider = FutureProvider<List<Pet>>((ref) async {
  // 인증 상태가 변경(로그인/로그아웃)되면 반려동물 목록도 다시 가져옵니다.
  // User 객체는 토큰 갱신마다 새로 만들어지므로, 사용자 ID가 바뀔 때만 다시 불러온다.
  final userId = ref.watch(currentUserProvider.select((u) => u?.id));
  if (userId == null) {
    return [];
  }
  final repo = ref.watch(petRepositoryProvider);
  return repo.getPets();
});

class PetManagementState {
  final bool isLoading;
  final String? error;
  final int targetGlucoseMin;
  final int targetGlucoseMax;

  PetManagementState({
    this.isLoading = false,
    this.error,
    this.targetGlucoseMin = 100,
    this.targetGlucoseMax = 250,
  });

  PetManagementState copyWith({
    bool? isLoading,
    String? error,
    int? targetGlucoseMin,
    int? targetGlucoseMax,
  }) {
    return PetManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null
      targetGlucoseMin: targetGlucoseMin ?? this.targetGlucoseMin,
      targetGlucoseMax: targetGlucoseMax ?? this.targetGlucoseMax,
    );
  }
}

final petManagementViewModelProvider =
    NotifierProvider<PetManagementViewModel, PetManagementState>(() {
      return PetManagementViewModel();
    });

class PetManagementViewModel extends Notifier<PetManagementState> {
  @override
  PetManagementState build() {
    return PetManagementState();
  }

  void onSpeciesChanged(String species) {
    if (species == 'dog') {
      state = state.copyWith(targetGlucoseMin: 100, targetGlucoseMax: 250);
    } else if (species == 'cat') {
      state = state.copyWith(targetGlucoseMin: 100, targetGlucoseMax: 300);
    }
  }

  void updateTargetGlucose(int min, int max) {
    state = state.copyWith(targetGlucoseMin: min, targetGlucoseMax: max);
  }

  Future<bool> savePet({
    required String name,
    required String species,
    String? breed,
    String? sex,
    bool isNeutered = false,
    DateTime? dateOfBirth,
    String? diagnosis,
    DateTime? diagnosedAt,
    String? insulinType,
    double? insulinUnitIu,
    double? weightKg,
    int? bodyConditionScore,
    String? vetClinic,
    String? vetMemo,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(petRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) throw '로그인이 필요합니다.';

      final client = Supabase.instance.client;

      // 1. user_families 테이블에서 내 family_id 조회
      final userFamiliesRes = await client
          .from('user_families')
          .select('family_id')
          .eq('user_id', currentUser.id)
          .limit(1)
          .maybeSingle();

      String? familyId = userFamiliesRes?['family_id'];

      // 2. family_id가 없다면 신규 생성 및 연결
      if (familyId == null) {
        final familyRes = await client
            .from('families')
            .insert({}) // DEFAULT VALUES로 생성
            .select('id')
            .single();

        familyId = familyRes['id'] as String;

        // user_families 테이블에 연결 저장
        await client.from('user_families').insert({
          'user_id': currentUser.id,
          'family_id': familyId,
          'role': 'owner',
        });
      }

      final newPet = Pet(
        id: '',
        familyId: familyId,
        name: name,
        species: species,
        breed: breed,
        sex: sex,
        isNeutered: isNeutered,
        dateOfBirth: dateOfBirth,
        diagnosis: diagnosis,
        diagnosedAt: diagnosedAt,
        insulinType: insulinType,
        insulinUnitIu: insulinUnitIu,
        targetGlucoseMin: state.targetGlucoseMin,
        targetGlucoseMax: state.targetGlucoseMax,
        weightKg: weightKg,
        bodyConditionScore: bodyConditionScore,
        vetClinic: vetClinic,
        vetMemo: vetMemo,
        // 인슐린 정보나 당뇨 진단이 있으면 당뇨 모듈을 켠다
        conditions: [
          if ((insulinType?.isNotEmpty ?? false) ||
              insulinUnitIu != null ||
              (diagnosis?.contains('당뇨') ?? false))
            'diabetes',
        ],
        insulinConcentration: VeterinaryGuidelines.concentrationOf(insulinType),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createPet(newPet);
      ref.invalidate(petsProvider); // 목록 갱신
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deletePetOrLeave(Pet pet) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(petRepositoryProvider);
      if (pet.role == 'owner') {
        await repo.deletePet(pet.id);
      } else {
        await repo.leaveFamily(pet.familyId);
      }

      // Select a different pet or clear selection if empty
      ref.invalidate(petsProvider);

      final currentSelected = ref.read(selectedPetIdProvider);
      if (currentSelected == pet.id) {
        ref.read(selectedPetIdProvider.notifier).selectPet(null);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
