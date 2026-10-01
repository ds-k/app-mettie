import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/record.dart';
import '../../data/models/pet.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/record_repository.dart';
import 'pet_management_view_model.dart'; // petsProvider 가져오기

// 홈·추이·AI 코치·건강수첩이 공유하는 "선택된 펫"과 그 기록 provider.

final selectedPetIdProvider = NotifierProvider<SelectedPetIdNotifier, String?>(() {
  return SelectedPetIdNotifier();
});

class SelectedPetIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectPet(String? id) {
    state = id;
  }
}

final currentPetProvider = Provider<Pet?>((ref) {
  final petsAsync = ref.watch(petsProvider);
  final selectedPetId = ref.watch(selectedPetIdProvider);

  return petsAsync.maybeWhen(
    data: (pets) {
      if (pets.isEmpty) return null;
      if (selectedPetId != null) {
        try {
          return pets.firstWhere((p) => p.id == selectedPetId);
        } catch (_) {
          return pets.first;
        }
      }
      return pets.first;
    },
    orElse: () => null,
  );
});

/// 펫별 최근 기록 실시간 스트림 (최신순). 다두 가정에서 다른 펫의 투여 일정도 이걸로 본다.
final petRecordsProvider = StreamProvider.family<List<Record>, String>((ref, petId) {
  return ref.watch(recordRepositoryProvider).watchRecords(petId);
});

/// 선택된 펫의 기록. 펫 목록을 다시 불러와도 ID가 같으면 구독을 유지한다.
final recordsStreamProvider = StreamProvider<List<Record>>((ref) {
  final petId = ref.watch(currentPetProvider.select((p) => p?.id));
  if (petId == null) return const Stream.empty();

  final repo = ref.watch(recordRepositoryProvider);
  return repo.watchRecords(petId);
});

/// 가족 구성원 표시 이름 (user_id → 이름).
final familyMembersProvider = FutureProvider.family<Map<String, String>, String>((ref, familyId) {
  return ref.watch(recordRepositoryProvider).fetchFamilyMembers(familyId);
});

/// 기록 작성자를 "나" 또는 가족 이름으로 보여 준다.
final writerNameProvider = Provider.family<String, String>((ref, writerId) {
  final myId = ref.watch(currentUserProvider.select((u) => u?.id));
  if (writerId == myId) return '나';
  final familyId = ref.watch(currentPetProvider.select((p) => p?.familyId));
  if (familyId == null) return '가족';
  return ref.watch(familyMembersProvider(familyId)).value?[writerId] ?? '가족';
});

/// 1분마다 갱신되는 현재 시각. 다음 투여까지 남은 시간 같은 표시에 쓴다.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
