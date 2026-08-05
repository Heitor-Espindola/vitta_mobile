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
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String? cpf;
  final DateTime? birthDate;
  final String? phone;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      name: map['fullName'] as String? ?? map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? '',
      cpf: map['cpfFormatted'] as String? ?? map['cpf'] as String?,
      birthDate: dateTimeFromMap(map['birthDate']),
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdAt: dateTimeFromMap(map['createdAt']),
      updatedAt: dateTimeFromMap(map['updatedAt']),
      lastLoginAt: dateTimeFromMap(map['lastLoginAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final cpfDigits = cpf?.replaceAll(RegExp(r'\D'), '') ?? '';
    final cpfFormatted = _formatCpf(cpfDigits);
    return {
      'uid': uid,
      'id': uid,
      'authUid': uid,
      'canAuthenticate': true,
      'name': name,
      'fullName': name,
      'normalizedName': name.trim().toLowerCase(),
      'email': email,
      'role': role,
      'roles': const ['user'],
      'accountStatus': 'active',
      'cpf': cpfDigits,
      'cpfDigits': cpfDigits,
      'cpfFormatted': cpfFormatted,
      'guardianIds': const <String>[],
      'dependentIds': const <String>[],
      'managedByUserIds': const <String>[],
      'birthDate': birthDate,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
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
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

String _formatCpf(String digits) {
  if (digits.length != 11) return digits;
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
      '${digits.substring(6, 9)}-${digits.substring(9)}';
}
