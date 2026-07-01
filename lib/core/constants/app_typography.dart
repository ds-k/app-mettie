import 'package:flutter/material.dart';
import 'app_colors.dart';

// ─── 폰트 패밀리 ─────────────────────────────────────────────────────────────
const String kFontFamily = 'Pretendard';

// ─── mettie-design.md 타이포그래피 스케일 ────────────────────────────────────

// display — 32px / Bold / 대시보드 상단 인사말
const TextStyle kDisplay = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.20,
  letterSpacing: -0.5,
  color: kInk,
);

// heading-1 — 24px / Bold / 페이지 레벨 헤드라인
const TextStyle kHeading1 = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1.30,
  letterSpacing: -0.3,
  color: kInk,
);

// heading-2 — 20px / SemiBold / 섹션 타이틀, 카드 타이틀
const TextStyle kHeading2 = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 20,
  fontWeight: FontWeight.w600,
  height: 1.30,
  letterSpacing: -0.2,
  color: kInk,
);

// heading-3 — 18px / SemiBold / 리스트 헤더, 모달 타이틀
const TextStyle kHeading3 = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.40,
  letterSpacing: 0,
  color: kInk,
);

// body-lg — 16px / Regular / AI 코칭 채팅 본문
const TextStyle kBodyLg = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.50,
  letterSpacing: 0,
  color: kCharcoal,
);

// body-lg-medium — 16px / Medium / 주요 강조 데이터
const TextStyle kBodyLgMedium = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.50,
  letterSpacing: 0,
  color: kCharcoal,
);

// body-md — 14px / Regular / 대시보드 타임라인 기록
const TextStyle kBodyMd = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.50,
  letterSpacing: 0,
  color: kCharcoal,
);

// button-md — 14px / SemiBold / Pill 버튼 라벨
const TextStyle kButtonMd = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  height: 1.30,
  letterSpacing: 0,
  color: kOnDark,
);

// caption — 12px / Medium / 시간/날짜 타임스탬프
const TextStyle kCaption = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.40,
  letterSpacing: 0,
  color: kSlate,
);

// ─── 혈당/수치 전용 (Tabular Figures 적용) ───────────────────────────────────
// 숫자 폭을 동일하게 맞춰 정렬 가독성 향상
TextStyle kGlucoseValue = kBodyLgMedium.copyWith(
  fontFeatures: kTabularFigures,
  color: kInk,
);
