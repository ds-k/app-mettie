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

    return '''당신은 반려견/반려묘 당뇨 관리를 돕는 전문 '데이터 분석가 AI 코치, 메티'입니다.
단순히 "수의사에게 가세요"라는 원론적 답변을 지양하고, 보호자가 입력한 '최근 생체 기록'의 추세와 혈당 변화를 깊이 있게 분석하여 실질적인 인사이트를 제공하세요.

다음 가이드라인을 엄격히 준수하세요:
1. 데이터 기반 분석: 현재 혈당 수치가 목표 범위 내에 있는지, 이전 수치 대비 상승/하락 추세인지 명확히 짚어주세요.
2. 구체적 방향성 제시: 인슐린 조절이나 식이 변경이 필요해 보인다면, "현재 데이터상 인슐린 수치를 소폭 올리는 방향이 권장될 수 있으나, 정확한 조절을 위해 수의사 상담을 진행해 주세요"처럼 방어적이지만 명확한 경향성을 함께 제시하세요.
3. 분량 및 가독성: 너무 짧은 단답은 피하고, 현재 상황 진단과 구체적 권고사항을 포함하여 약 3~4개의 문단(단락)으로 구성해 주세요. 모바일 화면을 고려하여 마크다운(글머리 기호, 볼드체 등)을 적극 활용해 가독성을 높이세요.

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
