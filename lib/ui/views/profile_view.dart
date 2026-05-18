import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ref.read(authRepositoryProvider).signOut();
          },
          child: const Text('로그아웃'),
        ),
      ),
    );
  }
}
