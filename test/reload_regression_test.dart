import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mettie/core/router/app_router.dart';
import 'package:mettie/data/models/pet.dart';
import 'package:mettie/data/models/record.dart';
import 'package:mettie/data/repositories/auth_repository.dart';
import 'package:mettie/data/repositories/pet_repository.dart';
import 'package:mettie/data/repositories/record_repository.dart';
import 'package:mettie/ui/view_models/dashboard_view_model.dart';
import 'package:mettie/ui/view_models/pet_management_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 대시보드 중복 리로드 회귀 테스트:
// 토큰 갱신 같은 인증 이벤트나 펫 목록 재조회가 라우터 재생성, 펫 재조회, 기록 재구독으로 번지지 않아야 한다.

class _FakePetRepository extends Fake implements PetRepository {
  int getPetsCalls = 0;

  @override
  Future<List<Pet>> getPets() async {
    getPetsCalls++;
    // 호출마다 새 인스턴스를 반환해 실제 Supabase 응답과 같은 조건을 만든다
    return [
      Pet(
        id: 'pet-1',
        familyId: 'family-1',
        name: '메티',
        species: 'cat',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];
  }
}

class _FakeRecordRepository extends Fake implements RecordRepository {
  int watchRecordsCalls = 0;

  @override
  Stream<List<Record>> watchRecords(String petId) {
    watchRecordsCalls++;
    return Stream.value(const []);
  }
}

AuthState _authEvent(
  AuthChangeEvent event,
  String userId, {
  String updatedAt = '2026-01-01T00:00:00Z',
}) {
  final user = User(
    id: userId,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: updatedAt,
  );
  return AuthState(
    event,
    Session(accessToken: 'token-${event.name}', tokenType: 'bearer', user: user),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<AuthState> authEvents;
  late _FakePetRepository petRepo;
  late _FakeRecordRepository recordRepo;
  late ProviderContainer container;

  setUp(() {
    authEvents = StreamController<AuthState>.broadcast();
    petRepo = _FakePetRepository();
    recordRepo = _FakeRecordRepository();
    container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => authEvents.stream),
        petRepositoryProvider.overrideWithValue(petRepo),
        recordRepositoryProvider.overrideWithValue(recordRepo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await authEvents.close();
  });

  Future<void> signIn() async {
    authEvents.add(_authEvent(AuthChangeEvent.initialSession, 'user-1'));
    await container.read(authStateProvider.future);
    await container.read(petsProvider.future);
  }

  test('토큰 갱신 시 GoRouter를 다시 만들지 않는다', () async {
    container.listen(routerProvider, (_, _) {});
    await signIn();
    final router = container.read(routerProvider);

    authEvents.add(_authEvent(AuthChangeEvent.tokenRefreshed, 'user-1'));
    await pumpEventQueue();

    expect(identical(container.read(routerProvider), router), isTrue);
  });

  test('같은 사용자의 정보만 바뀌면 펫 목록을 다시 불러오지 않는다', () async {
    container.listen(petsProvider, (_, _) {});
    await signIn();
    expect(petRepo.getPetsCalls, 1);

    // User는 필드 단위로 비교되므로, updatedAt 등이 바뀌는 이벤트에서만 재조회가 일어났다
    authEvents.add(
      _authEvent(
        AuthChangeEvent.userUpdated,
        'user-1',
        updatedAt: '2026-01-02T00:00:00Z',
      ),
    );
    await pumpEventQueue();
    await container.read(petsProvider.future);

    expect(petRepo.getPetsCalls, 1);
  });

  test('다른 사용자로 바뀌면 펫 목록을 다시 불러온다', () async {
    container.listen(petsProvider, (_, _) {});
    await signIn();

    authEvents.add(_authEvent(AuthChangeEvent.signedIn, 'user-2'));
    await pumpEventQueue();
    await container.read(petsProvider.future);

    expect(petRepo.getPetsCalls, 2);
  });

  test('펫 목록을 다시 불러와도 같은 펫이면 기록 구독을 다시 연결하지 않는다', () async {
    container.listen(recordsStreamProvider, (_, _) {});
    await signIn();
    await pumpEventQueue();
    expect(recordRepo.watchRecordsCalls, 1);

    container.invalidate(petsProvider);
    await container.read(petsProvider.future);
    await pumpEventQueue();
    container.read(recordsStreamProvider);

    expect(petRepo.getPetsCalls, 2);
    expect(recordRepo.watchRecordsCalls, 1);
  });
}
