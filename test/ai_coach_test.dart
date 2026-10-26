import 'package:flutter_test/flutter_test.dart';
import 'package:mettie/ui/view_models/ai_coach_view_model.dart';

ChatMessage u(String t) => ChatMessage(fromUser: true, content: t);
ChatMessage a(String t, {String? error}) => ChatMessage(fromUser: false, content: t, errorCode: error);

void main() {
  group('visibleReply', () {
    test('끝의 근거 표시를 숨긴다', () {
      expect(visibleReply('좋아지고 있어요.\n\n[[refs: R1, R2]]'), '좋아지고 있어요.');
    });

    test('스트리밍 도중 들어온 근거 표시 조각도 숨긴다', () {
      for (final partial in ['[', '[[', '[[r', '[[ref', '[[refs', '[[refs:', '[[refs: R1', '[[refs: R1]']) {
        expect(visibleReply('답이에요.\n\n$partial'), '답이에요.', reason: partial);
      }
    });

    test('본문 중간의 대괄호는 건드리지 않는다', () {
      expect(visibleReply('목표 [100–300] 안이에요.'), '목표 [100–300] 안이에요.');
    });
  });

  group('buildHistory', () {
    test('실패한 답과 빈 답을 빼고 user로 끝나게 만든다', () {
      final h = buildHistory([u('첫 질문'), a('', error: 'model_error'), u('다시 질문'), a('')]);
      expect(h.map((m) => m.role), ['user']);
      expect(h.single.content, '다시 질문');
    });

    test('정상 대화는 순서대로 보내고 근거 표시는 뺀다', () {
      final h = buildHistory([u('q1'), a('a1\n\n[[refs: R1]]'), u('q2'), a('')]);
      expect(h.map((m) => '${m.role}:${m.content}'), ['user:q1', 'assistant:a1', 'user:q2']);
    });

    test('최근 대화만 보내고 첫 턴은 항상 user', () {
      final msgs = <ChatMessage>[
        for (var i = 0; i < 8; i++) ...[u('q$i'), a('a$i')],
        u('last'),
        a(''),
      ];
      final h = buildHistory(msgs);
      expect(h.length, lessThanOrEqualTo(kAiHistoryTurns));
      expect(h.first.role, 'user');
      expect(h.last.content, 'last');
    });
  });
}
