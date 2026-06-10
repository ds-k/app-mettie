import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/llm_repository.dart';
import '../../utils/rag_context_injector.dart';
import 'dashboard_view_model.dart';

class ChatMessage {
  final String role; // 'user' or 'ai'
  final String content;

  ChatMessage({required this.role, required this.content});
}

enum AiCoachStatus { uninitialized, needsDownload, downloading, ready }

class AiCoachState {
  final AiCoachStatus status;
  final int downloadProgress;
  final List<ChatMessage> messages;
  final bool isGenerating;

  AiCoachState({
    this.status = AiCoachStatus.uninitialized,
    this.downloadProgress = 0,
    this.messages = const [],
    this.isGenerating = false,
  });

  AiCoachState copyWith({
    AiCoachStatus? status,
    int? downloadProgress,
    List<ChatMessage>? messages,
    bool? isGenerating,
  }) {
    return AiCoachState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

final aiCoachViewModelProvider = NotifierProvider<AiCoachViewModel, AiCoachState>(() {
  return AiCoachViewModel();
});

class AiCoachViewModel extends Notifier<AiCoachState> {
  @override
  AiCoachState build() {
    // 뷰모델 생성 시 바로 모델 상태 확인
    Future.microtask(() => checkModelStatus());
    return AiCoachState();
  }

  Future<void> checkModelStatus() async {
    final llmRepo = ref.read(llmRepositoryProvider);
    final isReady = await llmRepo.checkModelStatus();
    if (isReady) {
      state = state.copyWith(status: AiCoachStatus.ready);
    } else {
      state = state.copyWith(status: AiCoachStatus.needsDownload);
    }
  }

  Future<void> startDownload() async {
    final llmRepo = ref.read(llmRepositoryProvider);
    state = state.copyWith(status: AiCoachStatus.downloading, downloadProgress: 0);
    try {
      await llmRepo.downloadModel(
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
      );
      state = state.copyWith(status: AiCoachStatus.ready);
    } catch (e) {
      // 실패 시 다시 다운로드 유도 상태로 변경
      state = state.copyWith(status: AiCoachStatus.needsDownload);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isGenerating) return;

    // 1. 유저 메시지 즉시 추가
    final userMsg = ChatMessage(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isGenerating: true,
    );

    try {
      // 2. 현재 펫 및 기록 가져오기
      final currentPet = ref.read(currentPetProvider);
      if (currentPet == null) {
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(role: 'ai', content: '현재 등록된 반려동물이 없습니다. 먼저 펫을 등록해주세요.')
          ],
          isGenerating: false,
        );
        return;
      }

      final recordsAsync = ref.read(recordsStreamProvider);
      final recentRecords = recordsAsync.value?.take(5).toList() ?? [];

      // 3. RAG 텍스트 조합
      final fullPrompt = RagContextInjector.buildPrompt(
        userInput: text,
        pet: currentPet,
        recentRecords: recentRecords,
      );

      // 4. 빈 AI 메시지 홀더 추가
      final aiMsgIndex = state.messages.length;
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'ai', content: '')],
      );

      // 5. 스트리밍 응답 렌더링
      final llmRepo = ref.read(llmRepositoryProvider);
      final buffer = StringBuffer();

      await for (final token in llmRepo.generateCoreResponse(fullPrompt)) {
        buffer.write(token);

        final updatedMessages = List<ChatMessage>.from(state.messages);
        updatedMessages[aiMsgIndex] = ChatMessage(role: 'ai', content: buffer.toString());

        state = state.copyWith(messages: updatedMessages);
      }
    } catch (e) {
      final aiMsgIndex = state.messages.length - 1;
      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[aiMsgIndex] = ChatMessage(role: 'ai', content: '응답 생성 중 오류가 발생했습니다.\n$e');
      state = state.copyWith(messages: updatedMessages);
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }
}
