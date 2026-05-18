import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('대시보드')),
      body: const Center(child: Text('대시보드 준비 중...')),
    );
  }
}
