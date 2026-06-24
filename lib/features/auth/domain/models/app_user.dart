import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.cpf,
    this.birthDate,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String? cpf;
  final DateTime? birthDate;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? '',
      cpf: map['cpf'] as String?,
      birthDate: dateTimeFromMap(map['birthDate']),
      phone: map['phone'] as String?,
      createdAt: dateTimeFromMap(map['createdAt']),
      updatedAt: dateTimeFromMap(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'cpf': cpf,
      'birthDate': birthDate,
      'phone': phone,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? cpf,
    DateTime? birthDate,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
