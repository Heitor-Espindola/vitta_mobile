class Vaccine {
  const Vaccine({
    required this.id,
    required this.name,
    this.description,
    this.recommendedAge,
    this.doseCount,
    this.intervalDays,
  });

  final String id;
  final String name;
  final String? description;
  final String? recommendedAge;
  final int? doseCount;
  final int? intervalDays;

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      recommendedAge: map['recommendedAge'] as String?,
      doseCount: map['doseCount'] as int?,
      intervalDays: map['intervalDays'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'recommendedAge': recommendedAge,
      'doseCount': doseCount,
      'intervalDays': intervalDays,
    };
  }

  Vaccine copyWith({
    String? id,
    String? name,
    String? description,
    String? recommendedAge,
    int? doseCount,
    int? intervalDays,
  }) {
    return Vaccine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      recommendedAge: recommendedAge ?? this.recommendedAge,
      doseCount: doseCount ?? this.doseCount,
      intervalDays: intervalDays ?? this.intervalDays,
    );
  }
}
