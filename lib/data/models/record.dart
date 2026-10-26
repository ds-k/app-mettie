class Record {
  final String id;
  final String petId;
  final String writerId;
  final DateTime recordedAt;

  // Blood Glucose
  final int? glucoseValue;
  final String?
  glucoseType; // 'pre_meal', 'post_meal', 'fasting', 'nadir', 'spot'
  final String? measurementDevice;
  final bool isStressFlag;

  // Insulin
  final double? insulinDose;
  final String? insulinType;
  final String? injectionStatus; // 'given', 'skipped', 'partial'
  // 같은 회차 중복 투여 경고를 보호자가 확인하고 저장했는지 (서버 트리거 guard_duplicate_dose)
  final bool doseOverride;

  // Food / Nutrition
  final String? foodBrand;
  final String? foodType; // 'dry', 'wet', 'raw', 'mixed'
  final double? foodAmountG;
  final String? treatMemo;

  // Weight & Body Condition
  final double? weightKg;
  final int? bodyConditionScore;

  // Clinical Observations
  final String? waterIntake; // 'normal', 'increased', 'decreased'
  final String? urination; // 'normal', 'polyuria', 'decreased'
  final String? appetite; // 'good', 'partial', 'anorexic'
  final int? activityLevel; // 1~5
  final int vomitCount;
  final String? stoolStatus; // 'normal', 'diarrhea', 'constipation', 'none'

  // Misc
  final List<String>? symptomTags;
  final String? notes;
  final List<String>? attachments;

  final DateTime createdAt;

  Record({
    required this.id,
    required this.petId,
    required this.writerId,
    required this.recordedAt,
    this.glucoseValue,
    this.glucoseType,
    this.measurementDevice,
    this.isStressFlag = false,
    this.insulinDose,
    this.insulinType,
    this.injectionStatus,
    this.doseOverride = false,
    this.foodBrand,
    this.foodType,
    this.foodAmountG,
    this.treatMemo,
    this.weightKg,
    this.bodyConditionScore,
    this.waterIntake,
    this.urination,
    this.appetite,
    this.activityLevel,
    this.vomitCount = 0,
    this.stoolStatus,
    this.symptomTags,
    this.notes,
    this.attachments,
    required this.createdAt,
  });

  Record copyWith({
    String? id,
    String? petId,
    String? writerId,
    DateTime? recordedAt,
    int? glucoseValue,
    String? glucoseType,
    String? measurementDevice,
    bool? isStressFlag,
    double? insulinDose,
    String? insulinType,
    String? injectionStatus,
    bool? doseOverride,
    String? foodBrand,
    String? foodType,
    double? foodAmountG,
    String? treatMemo,
    double? weightKg,
    int? bodyConditionScore,
    String? waterIntake,
    String? urination,
    String? appetite,
    int? activityLevel,
    int? vomitCount,
    String? stoolStatus,
    List<String>? symptomTags,
    String? notes,
    List<String>? attachments,
    DateTime? createdAt,
  }) {
    return Record(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      writerId: writerId ?? this.writerId,
      recordedAt: recordedAt ?? this.recordedAt,
      glucoseValue: glucoseValue ?? this.glucoseValue,
      glucoseType: glucoseType ?? this.glucoseType,
      measurementDevice: measurementDevice ?? this.measurementDevice,
      isStressFlag: isStressFlag ?? this.isStressFlag,
      insulinDose: insulinDose ?? this.insulinDose,
      insulinType: insulinType ?? this.insulinType,
      injectionStatus: injectionStatus ?? this.injectionStatus,
      doseOverride: doseOverride ?? this.doseOverride,
      foodBrand: foodBrand ?? this.foodBrand,
      foodType: foodType ?? this.foodType,
      foodAmountG: foodAmountG ?? this.foodAmountG,
      treatMemo: treatMemo ?? this.treatMemo,
      weightKg: weightKg ?? this.weightKg,
      bodyConditionScore: bodyConditionScore ?? this.bodyConditionScore,
      waterIntake: waterIntake ?? this.waterIntake,
      urination: urination ?? this.urination,
      appetite: appetite ?? this.appetite,
      activityLevel: activityLevel ?? this.activityLevel,
      vomitCount: vomitCount ?? this.vomitCount,
      stoolStatus: stoolStatus ?? this.stoolStatus,
      symptomTags: symptomTags ?? this.symptomTags,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      writerId: json['writer_id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
      glucoseValue: json['glucose_value'] as int?,
      glucoseType: json['glucose_type'] as String?,
      measurementDevice: json['measurement_device'] as String?,
      isStressFlag: json['is_stress_flag'] as bool? ?? false,
      insulinDose: (json['insulin_dose'] as num?)?.toDouble(),
      insulinType: json['insulin_type'] as String?,
      injectionStatus: json['injection_status'] as String?,
      doseOverride: json['dose_override'] as bool? ?? false,
      foodBrand: json['food_brand'] as String?,
      foodType: json['food_type'] as String?,
      foodAmountG: (json['food_amount_g'] as num?)?.toDouble(),
      treatMemo: json['treat_memo'] as String?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      bodyConditionScore: json['body_condition_score'] as int?,
      waterIntake: json['water_intake'] as String?,
      urination: json['urination'] as String?,
      appetite: json['appetite'] as String?,
      activityLevel: json['activity_level'] as int?,
      vomitCount: json['vomit_count'] as int? ?? 0,
      stoolStatus: json['stool_status'] as String?,
      symptomTags: (json['symptom_tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notes: json['notes'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'pet_id': petId,
      'writer_id': writerId,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      if (glucoseValue != null) 'glucose_value': glucoseValue,
      if (glucoseType != null) 'glucose_type': glucoseType,
      if (measurementDevice != null) 'measurement_device': measurementDevice,
      'is_stress_flag': isStressFlag,
      if (insulinDose != null) 'insulin_dose': insulinDose,
      if (insulinType != null) 'insulin_type': insulinType,
      if (injectionStatus != null) 'injection_status': injectionStatus,
      if (doseOverride) 'dose_override': true,
      if (foodBrand != null) 'food_brand': foodBrand,
      if (foodType != null) 'food_type': foodType,
      if (foodAmountG != null) 'food_amount_g': foodAmountG,
      if (treatMemo != null) 'treat_memo': treatMemo,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyConditionScore != null)
        'body_condition_score': bodyConditionScore,
      if (waterIntake != null) 'water_intake': waterIntake,
      if (urination != null) 'urination': urination,
      if (appetite != null) 'appetite': appetite,
      if (activityLevel != null) 'activity_level': activityLevel,
      'vomit_count': vomitCount,
      if (stoolStatus != null) 'stool_status': stoolStatus,
      if (symptomTags != null) 'symptom_tags': symptomTags,
      if (notes != null) 'notes': notes,
      if (attachments != null) 'attachments': attachments,
      // created_at is handled by DB
    };
  }
}
