import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// 지원 언어. 기기 언어가 이 중 하나가 아니면 영어로 보여 준다.
const kSupportedLocales = [Locale('ko'), Locale('en'), Locale('ja')];

Locale resolveAppLocale(Locale? device, Iterable<Locale> supported) {
  if (device != null) {
    for (final l in supported) {
      if (l.languageCode == device.languageCode) return l;
    }
  }
  return const Locale('en');
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// intl DateFormat에 넘길 언어 코드
  String get localeName => AppLocalizations.of(this).localeName;
}
