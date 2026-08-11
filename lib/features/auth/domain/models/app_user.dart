import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.authUid,
    this.canAuthenticate = true,
    this.roles = const ['user'],
    this.accountStatus = 'active',
    this.guardianIds = const [],
    this.dependentIds = const [],
    this.managedByUserIds = const [],
    this.relationshipToGuardian,
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
  final String? authUid;
  final bool canAuthenticate;
  final List<String> roles;
  final String accountStatus;
  final List<String> guardianIds;
  final List<String> dependentIds;
  final List<String> managedByUserIds;
  final String? relationshipToGuardian;
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
      authUid: map['authUid'] as String?,
      canAuthenticate: map['canAuthenticate'] as bool? ?? true,
      roles: _stringList(map['roles'], fallback: const ['user']),
      accountStatus: map['accountStatus'] as String? ?? 'active',
      guardianIds: _stringList(map['guardianIds']),
      dependentIds: _stringList(map['dependentIds']),
      managedByUserIds: _stringList(map['managedByUserIds']),
      relationshipToGuardian: map['relationshipToGuardian'] as String?,
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
    final cpfDigits = cpfDigitsOnly(cpf ?? '');
    final cpfFormatted = formatCpf(cpfDigits);
    final formattedName = formatPersonName(name);
    return {
      'uid': uid,
      'id': uid,
      'authUid': authUid ?? (canAuthenticate ? uid : ''),
      'canAuthenticate': canAuthenticate,
      'name': formattedName,
      'fullName': formattedName,
      'normalizedName': normalizedPersonName(formattedName),
      'email': email,
      'role': role,
      'roles': roles,
      'accountStatus': accountStatus,
      'cpf': cpfDigits,
      'cpfDigits': cpfDigits,
      'cpfFormatted': cpfFormatted,
      'guardianIds': guardianIds,
      'dependentIds': dependentIds,
      'managedByUserIds': managedByUserIds,
      if (relationshipToGuardian != null)
        'relationshipToGuardian': relationshipToGuardian,
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
    String? authUid,
    bool? canAuthenticate,
    List<String>? roles,
    String? accountStatus,
    List<String>? guardianIds,
    List<String>? dependentIds,
    List<String>? managedByUserIds,
    String? relationshipToGuardian,
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
      authUid: authUid ?? this.authUid,
      canAuthenticate: canAuthenticate ?? this.canAuthenticate,
      roles: roles ?? this.roles,
      accountStatus: accountStatus ?? this.accountStatus,
      guardianIds: guardianIds ?? this.guardianIds,
      dependentIds: dependentIds ?? this.dependentIds,
      managedByUserIds: managedByUserIds ?? this.managedByUserIds,
      relationshipToGuardian:
          relationshipToGuardian ?? this.relationshipToGuardian,
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

List<String> _stringList(Object? value, {List<String> fallback = const []}) {
  if (value is! List) return fallback;
  return value.whereType<String>().toList(growable: false);
}
