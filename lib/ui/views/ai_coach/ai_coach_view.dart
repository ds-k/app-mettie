import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/constants/app_colors.dart';
import '../../view_models/ai_coach_view_model.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../widgets/glass_card.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'AI 코칭',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquarePlus, color: kBrandBlue),
            tooltip: '새 채팅 시작',
            onPressed: () {
              ref.read(aiCoachViewModelProvider.notifier).clearChat();
            },
          ),
        ],
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
          : _buildBodyContent(state),
    );
  }

  Widget _buildBodyContent(AiCoachState state) {
    switch (state.status) {
      case AiCoachStatus.uninitialized:
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kBrandBlue),
          ),
        );
      case AiCoachStatus.needsDownload:
        return _buildDownloadPrompt();
      case AiCoachStatus.downloading:
        return _buildDownloadProgress(state.downloadProgress);
      case AiCoachStatus.ready:
        return Column(
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kBrandBlue,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '메티가 답변을 작성 중입니다...',
                      style: TextStyle(color: kStone, fontSize: 12),
                    ),
                  ],
                ),
              ),
            _buildInputArea(state.isGenerating),
          ],
        );
    }
  }

  Widget _buildDownloadPrompt() {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(32.0),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.sparkle, size: 64, color: kBrandBlue),
            const SizedBox(height: 24),
            const Text(
              '온디바이스 AI 어시스턴트',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kBrandBlueDeep,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '메티의 AI 코치는 인터넷 연결 없이도\n기기 내부에서 안전하게 동작합니다.\n\n이를 위해 최초 1회, AI 모델 파일(약 2GB)을\n다운로드해야 합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: kInk, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(aiCoachViewModelProvider.notifier).startDownload();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Wi-Fi 환경에서 다운로드 시작',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(int progress) {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(32.0),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kBrandBlue),
            ),
            const SizedBox(height: 32),
            const Text(
              'AI 코칭 모델을 다운로드 중입니다...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kBrandBlueDeep,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress / 100 : null,
                backgroundColor: kBrandBlue.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(kBrandBlue),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            if (progress > 0)
              Text(
                '$progress%',
                style: const TextStyle(
                  color: kBrandBlueDeep,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              '앱을 백그라운드로 내리거나 이 화면을 벗어나면\n다운로드가 중단될 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kStone, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    Widget bubbleContent = isUser
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kBrandBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          )
        : GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 16.0,
            child: MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: kInk, fontSize: 16, height: 1.5),
                strong: const TextStyle(
                  color: kBrandBlueDeep,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: const TextStyle(color: kInk, fontSize: 16),
              ),
            ),
          );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: bubbleContent,
      ),
    );
  }

  Widget _buildInputArea(bool isGenerating) {
    return Container(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 120,
        top: 16,
      ), // Bottom nav 고려 넉넉히
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        border: const Border(top: BorderSide(color: Colors.white54)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: isGenerating ? '메티가 답변 중입니다...' : '혈당 수치나 상태를 질문해보세요',
                hintStyle: const TextStyle(color: kStone),
                filled: true,
                fillColor: kCanvas,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              enabled: !isGenerating,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isGenerating ? kBrandWarn : kBrandBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isGenerating ? LucideIcons.square : LucideIcons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: isGenerating
                  ? () => ref
                        .read(aiCoachViewModelProvider.notifier)
                        .stopGeneration()
                  : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
