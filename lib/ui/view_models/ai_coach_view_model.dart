import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ai_coach_repository.dart';
import 'dashboard_view_model.dart';

/// 대화 한 줄. AI 답변은 스트리밍 중에 content가 늘어난다.
class ChatMessage {
  final bool fromUser;
  final String content;
  final List<AiRef> refs;

  /// 답변 실패 코드: refused | model_error. 실패한 답은 다음 요청의 대화 기록에서 뺀다.
  final String? errorCode;

  const ChatMessage({required this.fromUser, required this.content, this.refs = const [], this.errorCode});

  ChatMessage copyWith({String? content, List<AiRef>? refs, String? errorCode}) => ChatMessage(
        fromUser: fromUser,
        content: content ?? this.content,
        refs: refs ?? this.refs,
        errorCode: errorCode ?? this.errorCode,
      );
}

enum AiCoachStatus { loading, needsConsent, ready, unavailable }

class AiCoachState {
  final AiCoachStatus status;
  final AiQuota? quota;
  final List<ChatMessage> messages;
  final bool isGenerating;

  /// 마지막 요청에서 참고한 기록 수 (화면 상단 안내)
  final int? recordsConsidered;

  /// 대화 바깥에 띄울 오류: quota_exceeded | network | ai_unavailable | pet_not_found
  final String? bannerError;

  const AiCoachState({
    this.status = AiCoachStatus.loading,
    this.quota,
    this.messages = const [],
    this.isGenerating = false,
    this.recordsConsidered,
    this.bannerError,
  });

  AiCoachState copyWith({
    AiCoachStatus? status,
    AiQuota? quota,
    List<ChatMessage>? messages,
    bool? isGenerating,
    int? recordsConsidered,
    String? bannerError,
    bool clearBanner = false,
  }) =>
      AiCoachState(
        status: status ?? this.status,
        quota: quota ?? this.quota,
        messages: messages ?? this.messages,
        isGenerating: isGenerating ?? this.isGenerating,
        recordsConsidered: recordsConsidered ?? this.recordsConsidered,
        bannerError: clearBanner ? null : (bannerError ?? this.bannerError),
      );
}

final aiCoachViewModelProvider = NotifierProvider<AiCoachViewModel, AiCoachState>(AiCoachViewModel.new);

/// 서버에 보내는 최근 대화 수. 그 이전 대화는 화면에만 남는다.
const int kAiHistoryTurns = 10;

/// 스트리밍 중 화면에 보이지 않게 할 근거 표시([[refs: …]])와 그 앞부분 조각
final _refsTail = RegExp(r'\s*\[(\[(r(e(f(s(:[^\]]*\]?\]?)?)?)?)?)?)?$');

String visibleReply(String raw) {
  final i = raw.indexOf('[[refs:');
  final cut = i >= 0 ? raw.substring(0, i) : raw;
  return cut.replaceFirst(_refsTail, '').trimRight();
}

/// 서버에 보낼 대화 기록: 실패하거나 비어 있는 답을 빼고, user로 시작·끝나며 번갈아 나오게 맞춘다.
List<({String role, String content})> buildHistory(List<ChatMessage> messages) {
  final out = <({String role, String content})>[];
  for (final m in messages) {
    final content = m.fromUser ? m.content.trim() : visibleReply(m.content);
    if (content.isEmpty || m.errorCode != null) continue;
    final role = m.fromUser ? 'user' : 'assistant';
    if (out.isNotEmpty && out.last.role == role) {
      // 연속된 같은 역할은 마지막 것만 남긴다 (실패한 답 뒤에 다시 물은 경우)
      out.removeLast();
    }
    out.add((role: role, content: content));
  }
  while (out.isNotEmpty && out.first.role != 'user') {
    out.removeAt(0);
  }
  final start = out.length > kAiHistoryTurns ? out.length - kAiHistoryTurns : 0;
  var recent = out.sublist(start);
  if (recent.isNotEmpty && recent.first.role != 'user') recent = recent.sublist(1);
  return recent;
}

class AiCoachViewModel extends Notifier<AiCoachState> {
  StreamSubscription<AiEvent>? _sub;

  @override
  AiCoachState build() {
    // 펫을 바꾸면 다른 아이의 대화가 섞이지 않도록 새로 시작한다
    ref.listen(currentPetProvider.select((p) => p?.id), (prev, next) {
      if (prev != next) _resetChat();
    });
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(refreshQuota);
    return const AiCoachState();
  }

  AiCoachRepository get _repo => ref.read(aiCoachRepositoryProvider);

  Future<void> refreshQuota() async {
    try {
      final quota = await _repo.quota();
      state = state.copyWith(
        quota: quota,
        status: quota.consented ? AiCoachStatus.ready : AiCoachStatus.needsConsent,
      );
    } catch (_) {
      if (state.status == AiCoachStatus.loading) {
        state = state.copyWith(status: AiCoachStatus.unavailable, bannerError: 'network');
      }
    }
  }

  Future<void> giveConsent() async {
    state = state.copyWith(status: AiCoachStatus.loading);
    try {
      await _repo.setConsent(true);
    } finally {
      await refreshQuota();
    }
  }

  void _resetChat() {
    _sub?.cancel();
    _sub = null;
    state = state.copyWith(messages: const [], isGenerating: false, clearBanner: true);
  }

  void clearChat() => _resetChat();

  void stop() {
    _sub?.cancel();
    _sub = null;
    state = state.copyWith(isGenerating: false);
  }

  Future<void> send(String text, {required String locale}) async {
    final question = text.trim();
    final petId = ref.read(currentPetProvider)?.id;
    if (question.isEmpty || state.isGenerating || petId == null) return;

    final messages = [
      ...state.messages,
      ChatMessage(fromUser: true, content: question),
      const ChatMessage(fromUser: false, content: ''),
    ];
    final history = buildHistory(messages);
    final answerIndex = messages.length - 1;
    state = state.copyWith(messages: messages, isGenerating: true, clearBanner: true);

    void updateAnswer(ChatMessage Function(ChatMessage) f) {
      final list = [...state.messages];
      if (answerIndex >= list.length) return;
      list[answerIndex] = f(list[answerIndex]);
      state = state.copyWith(messages: list);
    }

    final buffer = StringBuffer();
    var lastPaint = DateTime.now();
    _sub = _repo.ask(petId: petId, history: history, locale: locale).listen(
      (event) {
        switch (event) {
          case AiMeta(:final used, :final limit, :final records):
            state = state.copyWith(
              recordsConsidered: records,
              quota: AiQuota(used: used, limit: limit, consented: true),
            );
          case AiDelta(:final text):
            buffer.write(text);
            // 너무 잦은 다시 그리기를 막으려고 50ms마다 반영한다
            if (DateTime.now().difference(lastPaint).inMilliseconds > 50) {
              lastPaint = DateTime.now();
              updateAnswer((m) => m.copyWith(content: buffer.toString()));
            }
          case AiRefs(:final refs):
            updateAnswer((m) => m.copyWith(content: buffer.toString(), refs: refs));
          case AiDone():
            updateAnswer((m) => m.copyWith(content: buffer.toString()));
          case AiStreamError(:final code):
            // 거절·실패한 답은 일부만 받았더라도 완성된 답이 아니므로 내용을 버린다
            updateAnswer((m) => m.copyWith(content: '', errorCode: code));
        }
      },
      onError: (Object e) {
        final list = [...state.messages]..removeLast();
        if (e is AiCoachException && e.code == 'consent_required') {
          state = state.copyWith(messages: list, isGenerating: false, status: AiCoachStatus.needsConsent);
        } else if (e is AiCoachException) {
          state = state.copyWith(
            messages: list,
            isGenerating: false,
            bannerError: e.code,
            quota: e.used != null && e.limit != null
                ? AiQuota(used: e.used!, limit: e.limit!, consented: true)
                : null,
          );
        } else {
          state = state.copyWith(messages: list, isGenerating: false, bannerError: 'network');
        }
      },
      onDone: () {
        if (buffer.isNotEmpty) updateAnswer((m) => m.errorCode != null ? m : m.copyWith(content: buffer.toString()));
        state = state.copyWith(isGenerating: false);
        _sub = null;
      },
      cancelOnError: true,
    );
  }

  /// 마지막 질문을 다시 보낸다 (실패한 답 다시 시도)
  Future<void> retryLast({required String locale}) async {
    final lastQuestion = state.messages.lastWhere((m) => m.fromUser, orElse: () => const ChatMessage(fromUser: true, content: ''));
    if (lastQuestion.content.isEmpty) return;
    final trimmed = [...state.messages];
    while (trimmed.isNotEmpty && !trimmed.last.fromUser) {
      trimmed.removeLast();
    }
    if (trimmed.isNotEmpty) trimmed.removeLast();
    state = state.copyWith(messages: trimmed);
    await send(lastQuestion.content, locale: locale);
  }
}
