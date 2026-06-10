import 'package:intl/intl.dart';
import '../data/models/pet.dart';
import '../data/models/record.dart';

class RagContextInjector {
  /// 최근 기록(Record) 리스트를 자연어 타임라인 문자열로 직렬화합니다.
  static String serializeRecords(List<Record> records) {
    if (records.isEmpty) {
      return "최근 기록 없음";
    }

    final buffer = StringBuffer();
    buffer.writeln("최근 기록 요약:");

    for (final record in records) {
      final dateStr = DateFormat('MM월 dd일 HH:mm').format(record.recordedAt);

      final parts = <String>[];

      if (record.glucoseValue != null) {
        String typeStr = '';
        switch (record.glucoseType) {
          case 'pre_meal':
            typeStr = ' (식전)';
            break;
          case 'post_meal':
            typeStr = ' (식후)';
            break;
          case 'fasting':
            typeStr = ' (공복)';
            break;
          case 'nadir':
            typeStr = ' (Nadir)';
            break;
          case 'spot':
            typeStr = ' (임의)';
            break;
        }
        parts.add('혈당 ${record.glucoseValue} mg/dL$typeStr');
      }

      if (record.insulinDose != null) {
        parts.add('인슐린 ${record.insulinDose} IU 투여');
      }

      if (record.foodAmountG != null) {
        final foodName = record.foodBrand ?? '사료';
        parts.add('$foodName ${record.foodAmountG}g');
      }

      if (record.activityLevel != null) {
        parts.add('활동성 ${record.activityLevel}/5');
      }

      if (record.waterIntake == 'increased') {
        parts.add('음수량 증가 관찰');
      }

      if (parts.isNotEmpty) {
        buffer.writeln("[$dateStr] ${parts.join(', ')}");
      }
    }

    return buffer.toString().trim();
  }

  /// 챗 세션 생성 시 한 번만 주입되는 시스템 프롬프트(페르소나 및 전체 컨텍스트)
  static String buildSystemInstruction({
    required Pet pet,
    required List<Record> recentRecords,
  }) {
    final speciesStr = pet.species == 'cat'
        ? '고양이'
        : (pet.species == 'dog' ? '강아지' : pet.species);
    final breedStr = pet.breed ?? '알 수 없음';
    final diagnosisStr = pet.diagnosis ?? '당뇨(추정)';
    final insulinTypeStr = pet.insulinType ?? '미설정';
    final insulinUnitStr = pet.insulinUnitIu?.toString() ?? '?';
    final targetMin = pet.targetGlucoseMin ?? 100;
    final targetMax = pet.targetGlucoseMax ?? 300;

    final contextStr = serializeRecords(recentRecords);

    return '''당신은 반려견/반려묘 대사질환(당뇨 등) 보호자를 돕는 전문 '데이터 분석가 AI 코치, 메티'입니다.
단순히 "수의사에게 가세요"라는 회피성 답변을 지양하고, 주어진 기록의 '추세(Trend)'와 '통계'를 바탕으로 실질적이고 유용한 인사이트를 제공하세요.
단, 의료적 결정을 내릴 때는 "인슐린 수치를 올리는 것이 권장되지만, 수의사와 상담 후 진행하는 것이 좋습니다"와 같이 방어적이지만 명확한 경향성을 함께 제시해야 합니다.
답변은 구체적인 데이터 분석(현재 상태 진단 및 추세)과 향후 권고사항을 포함하되, 모바일 화면에서 읽기 편하도록 5~7문장 내외의 적절한 길이로 친절하고 논리적이게 설명하세요. 너무 짧거나 불필요하게 길어지지 않게 주의하세요.

[현재 반려동물 정보]
- 종/품종: $speciesStr / $breedStr
- 진단명: $diagnosisStr
- 처방 인슐린: $insulinTypeStr ${insulinUnitStr}IU
- 목표 혈당 범위: $targetMin ~ $targetMax mg/dL

[최근 생체 기록]
$contextStr

위 정보를 바탕으로 보호자의 질문에 친절하고 분석적으로 답변하세요. 마크다운(Markdown) 문법을 적극 활용하여 가독성을 높이세요.'''.trim();
  }

  /// 사용자의 입력만을 전달하는 단순 래퍼 (미래 확장성 고려)
  static String buildUserPrompt(String userInput) {
    return userInput.trim();
  }
}
