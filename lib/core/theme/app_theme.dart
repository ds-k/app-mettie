import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: kFontFamily,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.light(
          primary: kBrandBlue,
          onPrimary: kOnDark,
          secondary: kBrandBlueDeep,
          onSecondary: kOnDark,
          error: kBrandError,
          surface: kSurface,
          onSurface: kInk,
        ),
        // 앱 바 — 플랫, 테두리 없음, 투명 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: kInk,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: kHeading2,
        ),
        // 카드 — Elevation 0, hairline 테두리
        cardTheme: CardThemeData(
          elevation: 0,
          color: kCanvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusLg),
            side: const BorderSide(color: kHairline, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        // 기본 ElevatedButton — Black-pill (button-primary)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kInk,
            foregroundColor: kOnDark,
            elevation: 0,
            textStyle: kButtonMd,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        // FilledButton — Blue-pill (button-accent)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kBrandBlue,
            foregroundColor: kOnDark,
            elevation: 0,
            textStyle: kButtonMd,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        // 입력 필드 — 8px 라디어스, hairline 테두리
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCanvas,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusMd),
            borderSide: const BorderSide(color: kHairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusMd),
            borderSide: const BorderSide(color: kHairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusMd),
            borderSide: const BorderSide(color: kBrandBlue, width: 1.5),
          ),
          hintStyle: kBodyMd.copyWith(color: kStone),
          labelStyle: kBodyMd.copyWith(color: kSlate),
        ),
        // BottomNavigationBar — 높이 64px, hairline 상단 테두리
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kCanvas,
          selectedItemColor: kBrandBlue,
          unselectedItemColor: kStone,
          selectedLabelStyle: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(
          color: kHairline,
          thickness: 1,
          space: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: kDisplay,
          headlineLarge: kHeading1,
          headlineMedium: kHeading2,
          headlineSmall: kHeading3,
          bodyLarge: kBodyLg,
          bodyMedium: kBodyMd,
          labelLarge: kButtonMd,
          labelSmall: kCaption,
        ),
      );
}
