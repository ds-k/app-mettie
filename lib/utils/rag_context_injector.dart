import 'package:intl/intl.dart';
import '../data/models/pet.dart';
import '../data/models/record.dart';

class RagContextInjector {
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

      if (record.insulinDose != null || record.injectionStatus != null) {
        String statusStr = '';
        if (record.injectionStatus == 'skipped') {
          statusStr = ' (생략)';
        } else if (record.injectionStatus == 'partial') {
          statusStr = ' (일부 투여)';
        }

        if (record.insulinDose != null) {
          parts.add('인슐린 ${record.insulinDose} IU 투여$statusStr');
        } else if (statusStr.isNotEmpty) {
          parts.add('인슐린$statusStr');
        }
      }

      if (record.foodAmountG != null || (record.foodBrand != null && record.foodBrand!.isNotEmpty)) {
        final foodParts = <String>[];
        if (record.foodBrand != null && record.foodBrand!.isNotEmpty) {
          foodParts.add(record.foodBrand!);
        }
        if (record.foodAmountG != null) {
          foodParts.add('${record.foodAmountG}g');
        }
        parts.add('사료: ${foodParts.join(' ')}');
      }

      if (record.weightKg != null) {
        parts.add('체중 ${record.weightKg}kg');
      }

      if (record.activityLevel != null) {
        parts.add('활동성 ${record.activityLevel}/5');
      }

      if (record.waterIntake != null) {
        if (record.waterIntake == 'increased') parts.add('음수량 증가');
        if (record.waterIntake == 'decreased') parts.add('음수량 감소');
      }

      if (record.urination != null) {
        if (record.urination == 'polyuria') parts.add('다뇨');
        if (record.urination == 'decreased') parts.add('배뇨 감소');
      }

      if (record.appetite != null) {
        if (record.appetite == 'good') parts.add('식욕 좋음');
        if (record.appetite == 'partial') parts.add('식욕 부진');
        if (record.appetite == 'anorexic') parts.add('식욕 절폐');
      }

      if (record.vomitCount > 0) {
        parts.add('구토 ${record.vomitCount}회');
      }

      if (record.stoolStatus != null) {
        if (record.stoolStatus == 'diarrhea') parts.add('설사');
        if (record.stoolStatus == 'constipation') parts.add('변비');
      }

      if (record.notes != null && record.notes!.isNotEmpty) {
        parts.add('메모: ${record.notes!}');
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

    return '''당신은 반려견/반려묘 당뇨 관리를 돕는 전문 '데이터 분석가 AI 코치, 메티'입니다.
단순히 "수의사에게 가세요"라는 원론적 답변을 지양하고, 보호자가 입력한 '최근 생체 기록'의 추세와 혈당 변화를 깊이 있게 분석하여 실질적인 인사이트를 제공하세요.

다음 가이드라인을 엄격히 준수하세요:
1. 언어: 반드시 **한국어**로만 답변하세요. (영어 등 외국어 사용 금지)
2. 분량 제한: 모바일 화면에 맞게 **최대 200~300자 내외**로 아주 짧고 명확하게 작성하세요.
3. 형태: 장황한 서술을 피하고, 2~3개의 핵심 총알기호(Bullet points)로 요약하여 가독성을 극대화하세요.
4. 분석 및 권고: 현재 데이터가 목표 범위인지 짧게 짚고, 필요한 조치(예: "인슐린 소폭 상향 고려 및 수의사 상담 권장")를 명확히 제시하세요.

[현재 반려동물 정보]
- 종/품종: $speciesStr / $breedStr
- 질환 상태: $diagnosisStr
- 사용 중인 인슐린: $insulinTypeStr ${insulinUnitStr}IU
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
