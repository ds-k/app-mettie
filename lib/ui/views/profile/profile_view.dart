import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../view_models/profile_view_model.dart';
import 'widgets/profile_app_settings.dart';
import 'widgets/profile_account_info.dart';
import 'widgets/profile_family_management.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '프로필',
          style: TextStyle(color: kInk, fontWeight: FontWeight.bold),
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

            // 가족 관리 섹션
            const ProfileFamilyManagement(),

            const SizedBox(height: 32),

            // 앱 정보 및 설정 섹션
            const SizedBox(height: 32),
            const ProfileAppSettings(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
