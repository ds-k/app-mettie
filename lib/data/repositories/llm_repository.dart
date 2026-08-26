import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:mettie/ui/view_models/ai_coach_view_model.dart';

final llmRepositoryProvider = Provider<LlmRepository>((ref) {
  return LlmRepository();
});

class LlmRepository {
  bool _isInitialized = false;
  bool _useFallback = false;

  bool _isModelReady = false;
  InferenceChat? _activeChat;
  CancelToken? _cancelToken;

  bool get isInitialized => _isInitialized;
  bool get useFallback => _useFallback;
  bool get isModelReady => _isModelReady;

  // HuggingFace CDN URL for Gemma-4-E2B-it-int4
  static const String _modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  /// 앱 기동 시 FlutterGemma 초기화만 수행합니다. (가볍게 동작)
  Future<void> initialize() async {
    try {
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine()],
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('LLM Initialization Failed: $e');
      _isInitialized = false;
      _useFallback = true;
    }
  }

  /// 모델이 기기에 설치되어 있는지 확인하고, 설치되어 있다면 메모리에 로드(활성화)합니다.
  Future<bool> checkModelStatus() async {
    if (!_isInitialized) return false;

    try {
      final isInstalled = await FlutterGemma.isModelInstalled(
        'gemma-4-E2B-it.litertlm',
      );
      if (isInstalled) {
        // 이미 설치되어 있으면 다운로드를 건너뛰고 바로 활성화(Active Model Set) 됩니다.
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromNetwork(_modelUrl).install();

        _isModelReady = true;
        _useFallback = false;
        return true;
      }
    } catch (e) {
      debugPrint('LLM Check Status Failed: $e');
    }
    return false;
  }

  /// 명시적으로 모델을 다운로드하고 활성화합니다.
  Future<void> downloadModel({Function(int progress)? onProgress}) async {
    if (!_isInitialized) return;

    _cancelToken = CancelToken();

    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(_modelUrl).withCancelToken(_cancelToken!).withProgress((
        progress,
      ) {
        if (onProgress != null) {
          onProgress(progress);
        }
      }).install();

      _isModelReady = true;
      _useFallback = false;
    } catch (e) {
      if (CancelToken.isCancel(e) || e.toString().contains('cancelled')) {
        debugPrint('LLM Download Cancelled');
      } else {
        debugPrint('LLM Download Failed: $e');
        _useFallback = true;
        _isModelReady = false;
        throw Exception('모델 다운로드에 실패했습니다: $e');
      }
    } finally {
      _cancelToken = null;
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
  }

  /// 시스템 인스트럭션과 사용자 입력을 받아 채팅 세션을 유지하며 스트리밍 응답 반환
  Stream<String> generateCoreResponse({
    required List<ChatMessage> history,
    String? systemInstruction,
  }) async* {
    if (_useFallback || !_isModelReady) {
      // Fallback 로직
      yield "⚠️ 온디바이스 AI가 준비되지 않아 응답할 수 없습니다. 모델을 먼저 다운로드 해주세요.";
      return;
    }

    try {
      // 매 턴마다 세션을 재생성하고 최근 N개의 메시지만 주입하여 메모리 초과 방지
      if (_activeChat != null) {
        await _activeChat!.close();
      }

      final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
      _activeChat = await model.createChat(
        modelType: ModelType.gemma4,
        temperature: 0.1,
        systemInstruction: systemInstruction,
      );

      // 최적화를 위해 최근 최대 4개의 대화(질문 2개, 답변 2개 분량)만 컨텍스트로 유지
      const int maxHistoryCount = 4;
      final recentHistory = history.length > maxHistoryCount
          ? history.sublist(history.length - maxHistoryCount)
          : history;

      // 이전 대화 내역 주입 (마지막 사용자의 질문 제외)
      for (int i = 0; i < recentHistory.length - 1; i++) {
        final msg = recentHistory[i];
        if (msg.content.isNotEmpty) {
          await _activeChat!.addQueryChunk(
            Message(text: msg.content, isUser: msg.role == 'user'),
          );
        }
      }

      // 마지막 사용자의 질문 주입 및 응답 생성 시작
      final lastMsg = recentHistory.last;
      await _activeChat!.addQueryChunk(
        Message(text: lastMsg.content, isUser: true),
      );

      await for (final response in _activeChat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
    } catch (e) {
      yield "\n⚠️ 응답 생성 중 오류가 발생했습니다: $e";
    }
  }

  void stopGeneration() {
    _activeChat?.stopGeneration();
  }

  Future<void> clearChat() async {
    await _activeChat?.close();
    _activeChat = null;
  }
}
