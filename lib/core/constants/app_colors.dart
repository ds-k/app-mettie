import 'dart:ui';

import 'package:flutter/material.dart';

// ─── Brand & Accent ───────────────────────────────────────────────────────────
const Color kBrandBlue = Color(0xFF139CE1);
const Color kBrandBlueDeep = Color(0xFF0284C7);
const Color kBrandBlueSoft = Color(0xFFE0F2FE);
const Color kBrandWarn = Color(0xFFF59E0B);
const Color kBrandError = Color(0xFFE11D48);
const Color kWarmCoral = Color(0xFFF97316);

// ─── 상태 (값이 범위를 벗어났을 때만 쓴다) ──────────────────────────────────────
const Color kStatusOk = Color(0xFF059669);
const Color kStatusOkSoft = Color(0xFFD1FAE5);
const Color kStatusWarn = Color(0xFFD97706);
const Color kStatusWarnSoft = Color(0xFFFEF3C7);
const Color kStatusError = Color(0xFFE11D48);
const Color kStatusErrorSoft = Color(0xFFFFE4EA);
const Color kStatusSevere = Color(0xFFB91C1C);

// ─── 기록 종류 (타임라인 점, 그래프 표식) ───────────────────────────────────────
const Color kTypeInsulin = Color(0xFF139CE1);
const Color kTypeFood = Color(0xFFF97316);
const Color kTypeWeight = Color(0xFF8B5CF6);
const Color kTypeObservation = Color(0xFF94A3B8);

// ─── Surface ──────────────────────────────────────────────────────────────────
const Color kCanvas = Color(0xFFFFFFFF);
const Color kCanvasDark = Color(0xFF0F172A);
const Color kSurface = Color(0xFFF8FAFC);
const Color kSurfaceSoft = Color(0xFFF1F5F9);
const Color kHairline = Color(0xFFE2E8F0);
const Color kHairlineSoft = Color(0xFFF1F5F9);

// ─── Hero Atmospheric Gradients ───────────────────────────────────────────────
const Color kHeroSkyFrom = Color(0xFFE0F2FE);
const Color kHeroSkyTo = Color(0xFFFAFAF9);
const Color kHeroDarkFrom = Color(0xFF0284C7);
const Color kHeroDarkTo = Color(0xFF139CE1);

// ─── Text ─────────────────────────────────────────────────────────────────────
const Color kInk = Color(0xFF020617);
const Color kCharcoal = Color(0xFF334155);
const Color kSlate = Color(0xFF64748B);
const Color kStone = Color(0xFF94A3B8);
const Color kOnDark = Color(0xFFFFFFFF);

// ─── Border Radius Scale ──────────────────────────────────────────────────────
const double kRadiusXs = 4.0;
const double kRadiusMd = 8.0;
const double kRadiusLg = 12.0;
const double kRadiusXl = 16.0;
const double kRadiusFull = 9999.0;

// ─── Tabular figures FontFeature (혈당/수치 표기 시 적용) ──────────────────────
const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];
