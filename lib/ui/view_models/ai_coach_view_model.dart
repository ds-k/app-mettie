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
  bool _cancelRequested = false;

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
          // 사용자가 취소하여 상태가 변경되었다면 진행 상황 업데이트 무시
          if (state.status != AiCoachStatus.downloading) return;
          state = state.copyWith(downloadProgress: progress);
        },
      );
      // 다운로드가 성공적으로 끝났고 취소되지 않았을 때만 ready 상태로 변경
      if (state.status == AiCoachStatus.downloading) {
        state = state.copyWith(status: AiCoachStatus.ready);
      }
    } catch (e) {
      // 실패 시 원래 상태로 복귀
      if (state.status == AiCoachStatus.downloading) {
        state = state.copyWith(status: AiCoachStatus.needsDownload);
      }
    }
  }

  void cancelDownload() {
    // 다운로드 중단 시 상태를 needsDownload로 되돌림 (초기화)
    if (state.status == AiCoachStatus.downloading) {
      ref.read(llmRepositoryProvider).cancelDownload();
      state = state.copyWith(status: AiCoachStatus.needsDownload, downloadProgress: 0);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isGenerating) return;

    _cancelRequested = false;

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
      final systemInstruction = RagContextInjector.buildSystemInstruction(
        pet: currentPet,
        recentRecords: recentRecords,
      );

      // 4. 빈 AI 메시지 홀더 추가
      final aiMsgIndex = state.messages.length;
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'ai', content: '')],
      );

      // 모델에 전달할 유효한 기록 필터링 (최신 상태의 messages 이용, 비어있는 AI 메시지 홀더는 제외)
      final validHistory = state.messages.where((m) => m.content.trim().isNotEmpty).toList();

      // 5. 스트리밍 응답 렌더링 최적화 (UI 버벅임 방지)
      final llmRepo = ref.read(llmRepositoryProvider);
      final buffer = StringBuffer();
      
      int lastUpdate = DateTime.now().millisecondsSinceEpoch;

      await for (final token in llmRepo.generateCoreResponse(
        history: validHistory,
        systemInstruction: systemInstruction,
      )) {
        if (_cancelRequested) break;

        buffer.write(token);

        final now = DateTime.now().millisecondsSinceEpoch;
        // 50ms 마다 한 번씩만 UI 갱신 (너무 잦은 렌더링으로 인한 속도 저하 방지)
        if (now - lastUpdate > 50) {
          final updatedMessages = List<ChatMessage>.from(state.messages);
          updatedMessages[aiMsgIndex] = ChatMessage(role: 'ai', content: buffer.toString());
          state = state.copyWith(messages: updatedMessages);
          lastUpdate = now;
        }
      }
      
      // 스트림 종료 후 마지막으로 최종 내용 확실히 갱신
      final finalMessages = List<ChatMessage>.from(state.messages);
      finalMessages[aiMsgIndex] = ChatMessage(role: 'ai', content: buffer.toString());
      state = state.copyWith(messages: finalMessages);
    } catch (e) {
      final aiMsgIndex = state.messages.length - 1;
      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[aiMsgIndex] = ChatMessage(role: 'ai', content: '응답 생성 중 오류가 발생했습니다.\n$e');
      state = state.copyWith(messages: updatedMessages);
    } finally {
      state = state.copyWith(isGenerating: false);
      _cancelRequested = false;
    }
  }

  void stopGeneration() {
    if (state.isGenerating) {
      _cancelRequested = true;
      ref.read(llmRepositoryProvider).stopGeneration();
    }
  }

  Future<void> clearChat() async {
    state = state.copyWith(messages: []);
    await ref.read(llmRepositoryProvider).clearChat();
  }
}
