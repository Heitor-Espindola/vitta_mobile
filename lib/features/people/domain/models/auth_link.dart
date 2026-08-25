import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

class AuthLink {
  const AuthLink({
    required this.authUid,
    required this.personId,
    this.createdAt,
  });

  final String authUid;
  final String personId;
  final DateTime? createdAt;

  factory AuthLink.fromMap(String authUid, Map<String, dynamic> map) =>
      AuthLink(
        authUid: authUid,
        personId: map['personId'] is String ? map['personId'] as String : '',
        createdAt: dateTimeFromMap(map['createdAt']),
      );
}
