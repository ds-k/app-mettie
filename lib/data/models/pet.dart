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
    required this.createdAt,
    required this.updatedAt,
  });

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
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
      // created_at, updated_at are generally handled by DB default or triggers, but can be provided
    };
  }
}
