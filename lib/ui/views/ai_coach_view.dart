import 'package:flutter/material.dart';

class AiCoachView extends StatelessWidget {
  const AiCoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 코칭')),
      body: const Center(child: Text('AI 코칭 준비 중...')),
    );
  }
}
