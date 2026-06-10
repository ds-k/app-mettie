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

  /// 전체 프롬프트를 생성합니다.
  static String buildPrompt({
    required String userInput,
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

    return '''
[System] 당신은 대사질환(당뇨 등) 반려동물을 돌보는 보호자를 돕는 전문 수의사 AI '메티'입니다.
반려동물 정보: $speciesStr종 / 품종: $breedStr / 진단: $diagnosisStr / 처방 인슐린: $insulinTypeStr ${insulinUnitStr}IU / 목표 혈당: $targetMin~$targetMax mg/dL
아래 제공되는 동물의 실제 최신 생체 데이터를 '반드시' 최우선으로 참고하여 답변하세요.
외부 서버 통신 없이 폰 안에서 안전하게 작동 중입니다.

<Context>
$contextStr
</Context>

[User]
$userInput
'''
        .trim();
  }
}
