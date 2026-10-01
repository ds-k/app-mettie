/// 이름 뒤에 주격 조사를 붙인다: 나 → 내가, 엄마 → 엄마가, 지민 → 지민이가.
String subjectOf(String name) {
  if (name == '나') return '내가';
  if (name.isEmpty) return name;
  final last = name.runes.last;
  final hasFinalConsonant = last >= 0xAC00 && last <= 0xD7A3 && (last - 0xAC00) % 28 != 0;
  return hasFinalConsonant ? '$name이가' : '$name가';
}
