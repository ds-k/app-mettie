import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/legacy_model_cleanup.dart';
import '../../data/repositories/app_config_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/app_version.dart';

enum SplashStatus { initializing, checkingAuth, complete, updateRequired }

class SplashState {
  final SplashStatus status;
  final bool isAuth;

  /// 강제 업데이트 화면의 스토어 주소. 비어 있으면 버튼을 숨긴다
  final String? storeUrl;

  SplashState({this.status = SplashStatus.initializing, this.isAuth = false, this.storeUrl});

  SplashState copyWith({SplashStatus? status, bool? isAuth, String? storeUrl}) {
    return SplashState(
      status: status ?? this.status,
      isAuth: isAuth ?? this.isAuth,
      storeUrl: storeUrl ?? this.storeUrl,
    );
  }
}

final splashViewModelProvider = NotifierProvider<SplashViewModel, SplashState>(
  () {
    return SplashViewModel();
  },
);

class SplashViewModel extends Notifier<SplashState> {
  @override
  SplashState build() {
    return SplashState();
  }

  Future<void> initializeApp() async {
    // v1.0 온디바이스 AI 모델(약 2GB)이 남아 있으면 지운다. 기다리지 않는다
    unawaited(cleanupLegacyModelFiles());

    // 최소 지원 버전 확인. 네트워크가 안 되면 막지 않고 넘어간다
    try {
      final config = await ref.read(appConfigRepositoryProvider).fetch().timeout(const Duration(seconds: 4));
      final minimum = config['min_supported_version'] as String?;
      final current = (await PackageInfo.fromPlatform()).version;
      if (minimum != null && needsUpdate(current, minimum)) {
        final key = defaultTargetPlatform == TargetPlatform.iOS ? 'store_url_ios' : 'store_url_android';
        state = state.copyWith(status: SplashStatus.updateRequired, storeUrl: config[key] as String?);
        return;
      }
    } catch (e) {
      debugPrint('app_config 확인 건너뜀: $e');
    }

    state = state.copyWith(status: SplashStatus.checkingAuth);
    final authState = ref.read(authStateProvider);
    final isAuth = authState.value?.session != null;
    state = state.copyWith(status: SplashStatus.complete, isAuth: isAuth);
  }
}
