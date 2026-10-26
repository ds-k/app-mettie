import Anthropic from "npm:@anthropic-ai/sdk@1.3.0";

import { type Locale, STATIC_SYSTEM } from "./prompt.ts";

export const MODEL = "claude-opus-5-5";

export type ChatTurn = { role: "user" | "assistant"; content: string };

export type ModelEvent =
  | { type: "text"; text: string }
  | {
    type: "done";
    model: string;
    stopReason: string | null;
    fallbackUsed: boolean;
    usage: {
      input_tokens: number;
      output_tokens: number;
      cache_read_input_tokens: number;
      cache_creation_input_tokens: number;
    };
  };

export interface ModelRequest {
  context: string;
  messages: ChatTurn[];
  locale: Locale;
}

export interface ModelClient {
  readonly fake: boolean;
  stream(req: ModelRequest): AsyncIterable<ModelEvent>;
}

/** Claude Opus 5.5 스트리밍. 고정 지시문은 캐시하고, 안전 분류기 거절 시 서버가 권장 모델로 재시도한다. */
export function anthropicModel(apiKey: string): ModelClient {
  const client = new Anthropic({ apiKey });
  return {
    fake: false,
    async *stream({ context, messages }) {
      const stream = client.beta.messages.stream({
        model: MODEL,
        // 채팅 답변은 짧지만, 적응형 사고 토큰도 이 한도에 포함된다
        max_tokens: 8000,
        betas: ["server-side-fallback-2026-07-01"],
        fallbacks: "default",
        output_config: { effort: "low" },
        system: [
          { type: "text", text: STATIC_SYSTEM, cache_control: { type: "ephemeral" } },
          { type: "text", text: context },
        ],
        messages,
      });

      for await (const event of stream) {
        if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
          yield { type: "text", text: event.delta.text };
        }
      }

      const final = await stream.finalMessage();
      const fallbackUsed = final.content.some((b) => b.type === "fallback") ||
        (final.usage.iterations ?? []).some((it) => it.type === "fallback_message");
      yield {
        type: "done",
        model: final.model,
        stopReason: final.stop_reason,
        fallbackUsed,
        usage: {
          input_tokens: final.usage.input_tokens,
          output_tokens: final.usage.output_tokens,
          cache_read_input_tokens: final.usage.cache_read_input_tokens ?? 0,
          cache_creation_input_tokens: final.usage.cache_creation_input_tokens ?? 0,
        },
      };
    },
  };
}

const FAKE_REPLY: Record<Locale, string> = {
  ko: "**[테스트 응답]** 실제 AI가 아닌 개발용 가짜 응답입니다.\n\n- 최근 기록 {count}건을 받았어요.\n- 가장 최근 혈당은 {glucose}입니다.\n\n[[refs: R1]]",
  en: "**[Test reply]** This is a fake development reply, not the real AI.\n\n- I received {count} recent records.\n- The latest glucose reading is {glucose}.\n\n[[refs: R1]]",
  ja: "**［テスト応答］** 実際のAIではない開発用の仮の応答です。\n\n- 最近の記録を{count}件受け取りました。\n- 最新の血糖値は{glucose}です。\n\n[[refs: R1]]",
};

/** 개발용 가짜 모델. AI_COACH_FAKE=1일 때만 쓴다. 실제 요청 흐름(한도, 동의, 스트리밍, 근거)을 그대로 탄다. */
export function fakeModel(delayMs = 30): ModelClient {
  return {
    fake: true,
    async *stream({ context, locale }) {
      const count = (context.match(/^R\d+ \|/gm) ?? []).length;
      const glucose = context.match(/glucose (\d+) mg\/dL/)?.[1] ?? "-";
      const reply = FAKE_REPLY[locale].replace("{count}", String(count)).replace("{glucose}", glucose);
      for (const chunk of reply.match(/.{1,12}/gs) ?? []) {
        if (delayMs) await new Promise((r) => setTimeout(r, delayMs));
        yield { type: "text", text: chunk };
      }
      yield {
        type: "done",
        model: "fake",
        stopReason: "end_turn",
        fallbackUsed: false,
        usage: { input_tokens: 0, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 },
      };
    },
  };
}
