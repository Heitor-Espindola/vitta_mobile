class Child {
  const Child({
    required this.id,
    required this.responsibleId,
    required this.name,
    this.birthDate,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String responsibleId;
  final String name;
  final DateTime? birthDate;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'] as String? ?? '',
      responsibleId: map['responsibleId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      birthDate: _dateTimeFromMap(map['birthDate']),
      gender: map['gender'] as String?,
      createdAt: _dateTimeFromMap(map['createdAt']),
      updatedAt: _dateTimeFromMap(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'responsibleId': responsibleId,
      'name': name,
      'birthDate': birthDate,
      'gender': gender,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Child copyWith({
    String? id,
    String? responsibleId,
    String? name,
    DateTime? birthDate,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Child(
      id: id ?? this.id,
      responsibleId: responsibleId ?? this.responsibleId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _dateTimeFromMap(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
