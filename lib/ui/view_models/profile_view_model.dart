import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/pet_repository.dart';
import 'pet_management_view_model.dart';

class ProfileState {
  final bool isLoading;
  /// 화면에서 errorMessage()로 번역해 보여 준다
  final Object? error;
  final String? generatedCode;

  ProfileState({this.isLoading = false, this.error, this.generatedCode});

  ProfileState copyWith({
    bool? isLoading,
    Object? error,
    String? generatedCode,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      generatedCode: generatedCode ?? this.generatedCode,
    );
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(() {
      return ProfileViewModel();
    });

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return ProfileState();
  }

  Future<void> createInvitation(String familyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(petRepositoryProvider);
      final code = await repo.createInvitationCode(familyId);
      state = state.copyWith(isLoading: false, generatedCode: code);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<bool> joinFamily(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.joinFamilyWithCode(code);

      // 조인 성공 후 펫 리스트 새로고침
      ref.invalidate(petsProvider);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
