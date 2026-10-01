class Pet {
  final String id;
  final String familyId;
  final String name;
  final String species; // 'cat' or 'dog'
  final String? breed;
  final String? sex; // 'male' or 'female'
  final bool isNeutered;
  final DateTime? dateOfBirth;
  final String? diagnosis;
  final DateTime? diagnosedAt;
  final String? insulinType;
  final double? insulinUnitIu;
  final int? targetGlucoseMin; // Default 100
  final int? targetGlucoseMax; // Default: dog 400, cat 350
  final double? weightKg;
  final int? bodyConditionScore;
  final String? vetClinic;
  final String? vetMemo;
  final String? avatarUrl;
  final String? role; // e.g. 'owner', 'partner'

  // ─── 관리 계획 (질환 모듈) ───────────────────────────────────────────────
  final List<String> conditions; // 켜진 질환 모듈. 현재는 'diabetes'
  final List<String> dosingTimes; // 'HH:mm' 투여 시각
  final String? insulinConcentration; // 'U-40', 'U-100', 'U-300'
  final String? syringeType; // 'U-40', 'U-100', 'pen'
  final int hypoThreshold; // 저혈당 기준 (기본 80)
  final String? glucoseMeter;
  final String? defaultFoodWet;
  final String? defaultFoodDry;

  final DateTime createdAt;
  final DateTime updatedAt;

  Pet({
    required this.id,
    required this.familyId,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.isNeutered = false,
    this.dateOfBirth,
    this.diagnosis,
    this.diagnosedAt,
    this.insulinType,
    this.insulinUnitIu,
    this.targetGlucoseMin,
    this.targetGlucoseMax,
    this.weightKg,
    this.bodyConditionScore,
    this.vetClinic,
    this.vetMemo,
    this.avatarUrl,
    this.role,
    this.conditions = const [],
    this.dosingTimes = const [],
    this.insulinConcentration,
    this.syringeType,
    this.hypoThreshold = 80,
    this.glucoseMeter,
    this.defaultFoodWet,
    this.defaultFoodDry,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasDiabetes => conditions.contains('diabetes');
  bool get isCat => species == 'cat';

  Pet copyWith({
    String? id,
    String? familyId,
    String? name,
    String? species,
    String? breed,
    String? sex,
    bool? isNeutered,
    DateTime? dateOfBirth,
    String? diagnosis,
    DateTime? diagnosedAt,
    String? insulinType,
    double? insulinUnitIu,
    int? targetGlucoseMin,
    int? targetGlucoseMax,
    double? weightKg,
    int? bodyConditionScore,
    String? vetClinic,
    String? vetMemo,
    String? avatarUrl,
    String? role,
    List<String>? conditions,
    List<String>? dosingTimes,
    String? insulinConcentration,
    String? syringeType,
    int? hypoThreshold,
    String? glucoseMeter,
    String? defaultFoodWet,
    String? defaultFoodDry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      isNeutered: isNeutered ?? this.isNeutered,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      diagnosis: diagnosis ?? this.diagnosis,
      diagnosedAt: diagnosedAt ?? this.diagnosedAt,
      insulinType: insulinType ?? this.insulinType,
      insulinUnitIu: insulinUnitIu ?? this.insulinUnitIu,
      targetGlucoseMin: targetGlucoseMin ?? this.targetGlucoseMin,
      targetGlucoseMax: targetGlucoseMax ?? this.targetGlucoseMax,
      weightKg: weightKg ?? this.weightKg,
      bodyConditionScore: bodyConditionScore ?? this.bodyConditionScore,
      vetClinic: vetClinic ?? this.vetClinic,
      vetMemo: vetMemo ?? this.vetMemo,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      conditions: conditions ?? this.conditions,
      dosingTimes: dosingTimes ?? this.dosingTimes,
      insulinConcentration: insulinConcentration ?? this.insulinConcentration,
      syringeType: syringeType ?? this.syringeType,
      hypoThreshold: hypoThreshold ?? this.hypoThreshold,
      glucoseMeter: glucoseMeter ?? this.glucoseMeter,
      defaultFoodWet: defaultFoodWet ?? this.defaultFoodWet,
      defaultFoodDry: defaultFoodDry ?? this.defaultFoodDry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    String? parsedRole;
    if (json['families'] != null && json['families']['user_families'] != null) {
      final userFamilies = json['families']['user_families'] as List;
      if (userFamilies.isNotEmpty) {
        parsedRole = userFamilies.first['role'] as String?;
      }
    }

    return Pet(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      sex: json['sex'] as String?,
      isNeutered: json['is_neutered'] as bool? ?? false,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      diagnosis: json['diagnosis'] as String?,
      diagnosedAt: json['diagnosed_at'] != null ? DateTime.parse(json['diagnosed_at'] as String) : null,
      insulinType: json['insulin_type'] as String?,
      insulinUnitIu: (json['insulin_unit_iu'] as num?)?.toDouble(),
      targetGlucoseMin: json['target_glucose_min'] as int?,
      targetGlucoseMax: json['target_glucose_max'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      bodyConditionScore: json['body_condition_score'] as int?,
      vetClinic: json['vet_clinic'] as String?,
      vetMemo: json['vet_memo'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? parsedRole,
      conditions: (json['conditions'] as List?)?.cast<String>() ?? const [],
      // Postgres time[]은 'HH:mm:ss'로 오므로 'HH:mm'으로 자른다
      dosingTimes: (json['dosing_times'] as List?)
              ?.map((t) => (t as String).substring(0, 5))
              .toList() ??
          const [],
      insulinConcentration: json['insulin_concentration'] as String?,
      syringeType: json['syringe_type'] as String?,
      hypoThreshold: json['hypo_threshold'] as int? ?? 80,
      glucoseMeter: json['glucose_meter'] as String?,
      defaultFoodWet: json['default_food_wet'] as String?,
      defaultFoodDry: json['default_food_dry'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'family_id': familyId,
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex,
      'is_neutered': isNeutered,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'diagnosis': diagnosis,
      'diagnosed_at': diagnosedAt?.toIso8601String().split('T').first,
      'insulin_type': insulinType,
      'insulin_unit_iu': insulinUnitIu,
      'target_glucose_min': targetGlucoseMin,
      'target_glucose_max': targetGlucoseMax,
      'weight_kg': weightKg,
      'body_condition_score': bodyConditionScore,
      'vet_clinic': vetClinic,
      'vet_memo': vetMemo,
      'avatar_url': avatarUrl,
      'conditions': conditions,
      'dosing_times': dosingTimes,
      'insulin_concentration': insulinConcentration,
      'syringe_type': syringeType,
      'hypo_threshold': hypoThreshold,
      'glucose_meter': glucoseMeter,
      'default_food_wet': defaultFoodWet,
      'default_food_dry': defaultFoodDry,
      // role is purely client-side/joined, do not send back to pets table on insert/update
    };
  }
}
