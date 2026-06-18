import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/record.dart';
import '../../data/models/pet.dart';
import '../../data/repositories/record_repository.dart';
import 'pet_management_view_model.dart'; // petsProvider 가져오기

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

// Records 실시간 스트림
final recordsStreamProvider = StreamProvider<List<Record>>((ref) {
  final pet = ref.watch(currentPetProvider);
  if (pet == null) return const Stream.empty();
  
  final repo = ref.watch(recordRepositoryProvider);
  return repo.watchRecords(pet.id);
});

class DashboardState {
  final double? avgGlucose;
  final int? nadirGlucose;
  final int? peakGlucose;
  final DateTime? lastInsulinTime;
  final double? lastInsulinDose;
  final String? lastInsulinType;
  final String? activeAlarm; // 'hypoglycemia', 'hyperglycemia', or null

  DashboardState({
    this.avgGlucose,
    this.nadirGlucose,
    this.peakGlucose,
    this.lastInsulinTime,
    this.lastInsulinDose,
    this.lastInsulinType,
    this.activeAlarm,
  });
}

final dashboardViewModelProvider = NotifierProvider<DashboardViewModel, DashboardState>(() {
  return DashboardViewModel();
});

class DashboardViewModel extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    // recordsStreamProvider를 구독하여 데이터가 바뀔 때마다 상태를 업데이트합니다.
    ref.listen<AsyncValue<List<Record>>>(recordsStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _calculateSummary(next.value!);
      }
    });
    
    return DashboardState();
  }

  void _calculateSummary(List<Record> records) {
    if (records.isEmpty) {
      state = DashboardState();
      return;
    }

    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
    final todayRecords = records.where((r) => 
      r.recordedAt.isAfter(twoWeeksAgo) || r.recordedAt.isAtSameMomentAs(twoWeeksAgo)
    ).toList();

    double? avgGlucose;
    int? nadirGlucose;
    int? peakGlucose;

    final glucoseRecords = todayRecords.where((r) => r.glucoseValue != null).toList();
    if (glucoseRecords.isNotEmpty) {
      final sum = glucoseRecords.fold<int>(0, (prev, r) => prev + r.glucoseValue!);
      avgGlucose = sum / glucoseRecords.length;
      
      nadirGlucose = glucoseRecords.map((r) => r.glucoseValue!).reduce((a, b) => a < b ? a : b);
      peakGlucose = glucoseRecords.map((r) => r.glucoseValue!).reduce((a, b) => a > b ? a : b);
    }

    // 최근 인슐린 기록 찾기
    final insulinRecords = records.where((r) => r.insulinDose != null).toList();
    DateTime? lastInsulinTime;
    double? lastInsulinDose;
    String? lastInsulinType;
    
    if (insulinRecords.isNotEmpty) {
      // 내림차순 정렬되어 있으므로 첫 번째가 최신
      insulinRecords.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      final latest = insulinRecords.first;
      lastInsulinTime = latest.recordedAt;
      lastInsulinDose = latest.insulinDose;
      lastInsulinType = latest.insulinType;
    }

    // 알람 평가 (최근 1개 기록 기준)
    String? alarm;
    if (glucoseRecords.isNotEmpty) {
      glucoseRecords.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      final latestGlucose = glucoseRecords.first.glucoseValue;
      final pet = ref.read(currentPetProvider);
      
      alarm = ref.read(recordRepositoryProvider).evaluateGlucoseAlarm(
        latestGlucose, 
        pet?.targetGlucoseMax,
      );
    }

    state = DashboardState(
      avgGlucose: avgGlucose,
      nadirGlucose: nadirGlucose,
      peakGlucose: peakGlucose,
      lastInsulinTime: lastInsulinTime,
      lastInsulinDose: lastInsulinDose,
      lastInsulinType: lastInsulinType,
      activeAlarm: alarm,
    );
  }
}
