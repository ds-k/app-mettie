import 'package:flutter/material.dart';

class PetManagementView extends StatelessWidget {
  const PetManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('반려동물 관리')),
      body: const Center(child: Text('반려동물 정보 준비 중...')),
    );
  }
}
