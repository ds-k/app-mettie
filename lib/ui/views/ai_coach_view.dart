import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../view_models/ai_coach_view_model.dart';
import '../view_models/dashboard_view_model.dart';

class AiCoachView extends ConsumerStatefulWidget {
  const AiCoachView({super.key});

  @override
  ConsumerState<AiCoachView> createState() => _AiCoachViewState();
}

class _AiCoachViewState extends ConsumerState<AiCoachView> {
  final TextEditingController _textController = TextEditingController();

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    FocusScope.of(context).unfocus();
    
    ref.read(aiCoachViewModelProvider.notifier).sendMessage(text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachViewModelProvider);
    final currentPet = ref.watch(currentPetProvider);

    return Scaffold(
      backgroundColor: kCanvas,
      appBar: AppBar(
        title: const Text('AI 코칭', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: kCanvas,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: kBrandWarn.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: kBrandWarn),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '본 가이드는 참고용이며, 의료진의 전문적 상담을 대체할 수 없습니다. 최종 투약 결정 책임은 보호자에게 있습니다.',
                    style: TextStyle(fontSize: 12, color: kBrandWarn),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: currentPet == null
          ? const Center(
              child: Text(
                '먼저 반려동물을 등록해주세요',
                style: TextStyle(color: kStone, fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true, // 하단부터 스크롤
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      // reverse이므로 최신 메시지가 배열 마지막에 있지만 index 0에 그려짐
                      final msg = state.messages[state.messages.length - 1 - index];
                      final isUser = msg.role == 'user';
                      
                      return _buildMessageBubble(msg.content, isUser);
                    },
                  ),
                ),
                if (state.isGenerating)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kBrandTeal),
                        ),
                        SizedBox(width: 8),
                        Text('메티가 답변을 작성 중입니다...', style: TextStyle(color: kStone, fontSize: 12)),
                      ],
                    ),
                  ),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? kBrandTeal : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: kHairline),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : kInk,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32, top: 16), // Safe area bottom 대신 넉넉히
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kHairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '혈당 수치나 상태를 질문해보세요',
                hintStyle: const TextStyle(color: kStone),
                filled: true,
                fillColor: kCanvas,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: kBrandTeal,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
