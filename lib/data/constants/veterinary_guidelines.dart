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
    '기타',
  ];

  /// 인슐린 종류별 농도. 반려동물 전용 인슐린(캐닌슐린, 프로징크)은 U-40이고 사람용은 대부분 U-100이다.
  /// 주사기 눈금이 농도와 다르면 실제 투여량이 2.5배까지 달라진다.
  static String? concentrationOf(String? insulinType) {
    if (insulinType == null || insulinType.isEmpty || insulinType == '기타') {
      return null;
    }
    if (insulinType.contains('캐닌슐린') ||
        insulinType.contains('Vetsulin') ||
        insulinType.contains('프로징크')) {
      return 'U-40';
    }
    if (insulinType.contains('투제오')) return 'U-300';
    return 'U-100';
  }
}
