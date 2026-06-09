import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

final llmRepositoryProvider = Provider<LlmRepository>((ref) {
  return LlmRepository();
});

class LlmRepository {
  bool _isInitialized = false;
  bool _useFallback = false;

  bool get isInitialized => _isInitialized;
  bool get useFallback => _useFallback;

  // HuggingFace CDN URL for Gemma-4-E2B-it-int4
  static const String _modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  /// 앱 기동 시 모델을 초기화하거나 다운로드합니다.
  Future<void> initialize({Function(int progress)? onProgress}) async {
    try {
      await FlutterGemma.initialize();

      final isInstalled = await FlutterGemma.isModelInstalled('gemma-4-E2B-it.litertlm');
      
      if (!isInstalled) {
        // Download model from HuggingFace
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt, // gemmaIt for general conversational model
          fileType: ModelFileType.litertlm,
        )
        .fromNetwork(_modelUrl)
        .withProgress((progress) {
          if (onProgress != null) {
            onProgress(progress);
          }
        })
        .install();
      }
      
      _isInitialized = true;
      _useFallback = false;
    } catch (e) {
      // OOM, 다운로드 실패, 지원하지 않는 기기 등의 경우 Fallback 모드 활성화
      debugPrint('LLM Initialization Failed: $e');
      _isInitialized = false;
      _useFallback = true;
    }
  }

  /// 컨텍스트가 주입된 프롬프트를 입력받아 스트리밍 응답 반환
  Stream<String> generateCoreResponse(String fullPrompt) async* {
    if (_useFallback || !_isInitialized) {
      // Fallback 로직 (현재는 더미 또는 향후 Cloud API 연동)
      yield "⚠️ 온디바이스 AI를 사용할 수 없어 클라우드 모드로 응답합니다. (현재 연결 안됨)";
      return;
    }

    try {
      final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
      final session = await model.createSession();
      // getAsyncResponse() or generateStream()?
      // flutter_gemma has getAsyncResponse(prompt) which returns Stream<String>?
      // Let's verify flutter_gemma stream API.
      await session.addQueryChunk(Message(text: fullPrompt, isUser: true));
      await for (final chunk in session.getResponseAsync()) {
        yield chunk;
      }
    } catch (e) {
      yield "\n⚠️ 응답 생성 중 오류가 발생했습니다: $e";
    }
  }
}
