class VeterinaryGuidelines {
  /// 사용 가능한 인슐린 드롭다운 목록
  static const List<String> insulinTypes = [
    '캐닌슐린(Vetsulin)',
    '란투스(Lantus)',
    '레베미어(Levemir)',
    '프로징크(ProZinc)',
    '휴물린N/노볼린N(NPH)',
    '트레시바(Tresiba)',
    '투제오(Toujeo)',
    '기타'
  ];

  /// 주요 인슐린 특성 (RAG 컨텍스트 주입용)
  static const Map<String, String> insulinDictionary = {
    '캐닌슐린(Vetsulin)': '중간형 인슐린. 개와 고양이 모두 자주 사용. 개는 약 12시간, 고양이는 8~12시간 작용하며 피크(최대 효과)는 4~8시간 사이에 발생. U-40 전용 주사기 사용 필수.',
    '란투스(Lantus)': '장기형 인슐린(Glargine U-100). 고양이의 관해 유도에 흔히 쓰임. 무피크(Peakless)에 가까워 혈당 곡선이 완만함. 12~24시간 작용. U-100 전용 주사기 사용.',
    '레베미어(Levemir)': '장기형 인슐린(Detemir U-100). 란투스와 유사하게 완만하게 작용. 개에게 투여 시 다른 인슐린보다 수용체가 강력하게 반응하여 최대 4배 강할 수 있으므로 세심한 용량 조절이 필수. U-100 전용 주사기 사용.',
    '프로징크(ProZinc)': '장기형 인슐린(PZI). 동물 전용. 고양이 기준 피크는 5~7시간, 작용시간은 10~24시간. 개는 최대 24시간까지 작용 가능. U-40 전용 주사기 사용.',
    '휴물린N/노볼린N(NPH)': '중간형 인슐린. 개에게 주로 사용되며 피크는 2~10시간. 고양이에겐 작용시간이 너무 짧아 부적합한 경우가 많음. U-100 전용 주사기 사용.',
    '트레시바(Tresiba)': '초장기형 인슐린(Degludec). 작용시간이 42시간 이상으로 매우 길고 평탄하여 하루 1회 투여 가능성이 있음.',
    '투제오(Toujeo)': '초고농축 장기형 기저 인슐린(Glargine 300U/mL). 란투스와 성분은 같으나 3배 농축되어 피크가 아예 없는(Peakless) 안정적인 릴리즈를 보임. 소형 동물에겐 세밀한 용량 조절(0.5U 등)이 매우 어려워 수의사의 극히 세밀한 지도가 필요함.',
  };

  /// 일반 당뇨 관리 가이드라인 (RAG 컨텍스트 주입용)
  static const String generalGuidelines = '''
[일반 당뇨 관리 가이드라인 (AAHA 기준)]
- 식이 관리(Diet): 고양이는 고단백/저탄수화물(ME 기준 단백질 40% 이상)이 필수적입니다. 강아지는 특정 성분보다 '매일 같은 시간, 일관된 칼로리와 성분의 식단'이 혈당 안정화에 훨씬 중요합니다.
- 체중 및 비만도(BCS) 관리: 동물의 적정 체중은 종(Breed)에 따라 편차가 극심합니다. 단순 kg 수치보다는 신체충실지수(BCS) 9단계 중 4~5단계를 목표로 평가해야 합니다. 비만인 경우 주당 체중의 0.5% ~ 2% 감량을 목표로 하며, 급격한 체중 감소는 지방간 등 합병증을 유발합니다.
- 저혈당 대처(Hypoglycemia): 무기력, 방향감각 상실, 심한 떨림, 경련 발생 시 즉시 카로시럽(설탕물/꿀 등)을 잇몸에 바르고 즉각 수의사에게 응급 연락해야 합니다.
- 임의 용량 변경 경고: 인슐린 용량은 최소 3~7일간의 추세(곡선)를 보고 변경해야 하며, 단일 측정값에 기반한 보호자의 임의 증량은 저혈당(소모기 효과 포함) 위험이 있습니다.
''';

  /// 특정 인슐린에 대한 특성 텍스트 반환
  static String getInsulinInfo(String? type) {
    if (type == null || type.isEmpty) return '';
    for (final key in insulinDictionary.keys) {
      final shortName = key.split('(').first.trim();
      if (type.contains(shortName) || type == key) {
        return '현재 투여 중인 [\$key]의 특성: \${insulinDictionary[key]}';
      }
    }
    return ''; // 사전에 없거나 '기타'인 경우
  }
}
