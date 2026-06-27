import 'package:intl/intl.dart';
import '../data/models/pet.dart';
import '../data/models/record.dart';
import '../data/constants/veterinary_guidelines.dart';

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

        String typeStr = '';
        if (record.insulinType != null && record.insulinType!.isNotEmpty) {
          typeStr = ' [${record.insulinType}]';
        }

        if (record.insulinDose != null) {
          parts.add('인슐린$typeStr ${record.insulinDose} IU 투여$statusStr');
        } else if (statusStr.isNotEmpty) {
          parts.add('인슐린$typeStr$statusStr');
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
    final allInsulinInfo = VeterinaryGuidelines.insulinDictionary.entries
        .map((e) => '- ${e.key}: ${e.value}')
        .join('\n');
    final generalGuidelines = VeterinaryGuidelines.generalGuidelines;

    return '''당신은 확신에 찬 반려견/반려묘 당뇨 관리 전문 수의학 데이터 코치, '메티'입니다.
무조건 "수의사와 상담하라"며 답변을 회피하거나 원론적인 면책 조항을 반복하지 마십시오.

다음 가이드라인을 엄격히 준수하세요:
1. 언어: 반드시 **한국어**로만 답변하세요.
2. 분량 및 형태: 기기 메모리 한계로 인해 **답변의 전체 길이는 절대로 250자를 초과해서는 안 됩니다**. 2~3개의 핵심 총알기호(Bullet points)로만 극도로 간결하게 작성하세요.
3. 자신감 있는 코칭: 제공된 [수의학 가이드라인]과 [인슐린 특성]을 바탕으로 현재 기록이 정상 범주인지 분석하고, 수치가 높거나 낮을 때 보호자가 당장 취해야 할 행동을 구체적이고 실질적으로 가이드하세요.
4. 유연한 지식 활용: [최근 생체 기록]에 기반하여 상태를 분석하되, 일반적인 의학 지식을 묻는다면 수의학적 기본 지식을 바탕으로 명쾌하고 짧게 설명해 주세요.

[현재 반려동물 정보]
- 종/품종: $speciesStr / $breedStr
- 질환 상태: $diagnosisStr
- 사용 중인 인슐린: $insulinTypeStr ${insulinUnitStr}IU
- 목표 혈당 범위: $targetMin ~ $targetMax mg/dL

[전체 인슐린 종류 및 특성]
$allInsulinInfo

$generalGuidelines

[최근 생체 기록]
$contextStr

위 정보를 바탕으로 보호자의 질문에 친절하고 분석적으로 답변하세요. 마크다운(Markdown) 문법을 적극 활용하여 가독성을 높이세요.'''.trim();
  }

  /// 사용자의 입력만을 전달하는 단순 래퍼 (미래 확장성 고려)
  static String buildUserPrompt(String userInput) {
    return userInput.trim();
  }
}
