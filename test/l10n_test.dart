import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mettie/l10n/l10n.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();

final _placeholder = RegExp(r'\{(\w+)[,}]');

void main() {
  final ko = _arb('ko');

  for (final lang in ['en', 'ja']) {
    group('app_$lang.arb', () {
      final other = _arb(lang);

      test('한국어(템플릿)와 키가 같다', () {
        expect(_keys(other).difference(_keys(ko)), isEmpty, reason: '$lang에만 있는 키');
        expect(_keys(ko).difference(_keys(other)), isEmpty, reason: '$lang에 빠진 키');
      });

      test('빈 번역이 없다', () {
        final empty = _keys(other).where((k) => (other[k] as String).trim().isEmpty);
        expect(empty, isEmpty);
      });

      test('자리 표시자가 한국어와 같다', () {
        for (final k in _keys(ko)) {
          final want = _placeholder.allMatches(ko[k] as String).map((m) => m.group(1)).toSet();
          final got = _placeholder.allMatches(other[k] as String).map((m) => m.group(1)).toSet();
          expect(got.containsAll(want), isTrue, reason: '$lang.$k 에 {${want.difference(got).join(', ')}} 없음');
        }
      });
    });
  }

  test('지원하지 않는 기기 언어는 영어로, 지원 언어는 그대로 고른다', () {
    expect(resolveAppLocale(const Locale('ja', 'JP'), kSupportedLocales), const Locale('ja'));
    expect(resolveAppLocale(const Locale('ko', 'KR'), kSupportedLocales), const Locale('ko'));
    expect(resolveAppLocale(const Locale('fr'), kSupportedLocales), const Locale('en'));
    expect(resolveAppLocale(null, kSupportedLocales), const Locale('en'));
  });
}
