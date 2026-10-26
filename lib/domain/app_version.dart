/// '1.10.2' 같은 버전 문자열 비교. 숫자가 아닌 꼬리(+13, -beta)는 무시한다.
int compareVersions(String a, String b) {
  List<int> parse(String v) => v
      .split(RegExp(r'[+-]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
  final x = parse(a), y = parse(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0).compareTo(i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// 현재 버전이 최소 지원 버전보다 낮으면 업데이트가 필요하다.
bool needsUpdate(String current, String minimum) => compareVersions(current, minimum) < 0;
