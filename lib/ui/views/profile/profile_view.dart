import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../view_models/profile_view_model.dart';
import 'widgets/profile_app_settings.dart';
import 'widgets/profile_account_info.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileViewModelProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: kBrandError),
        );
        ref.read(profileViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: kInk),
        title: Text(
          context.l10n.commonSettings,
          style: const TextStyle(color: kInk, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 계정 정보 섹션
            const ProfileAccountInfo(),
            const SizedBox(height: 32),

            // 가족 관리는 건강수첩으로 옮겼다
            // 앱 정보 및 설정 섹션
            const ProfileAppSettings(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
