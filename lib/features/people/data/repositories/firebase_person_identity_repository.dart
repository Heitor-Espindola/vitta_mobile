import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vitta_mobile/features/people/domain/models/auth_link.dart';
import 'package:vitta_mobile/features/people/domain/repositories/person_identity_repository.dart';
import 'package:vitta_mobile/features/people/domain/services/person_identity_resolver.dart';

class FirebasePersonIdentityRepository implements PersonIdentityRepository {
  FirebasePersonIdentityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String> resolvePersonId(String authUid) async {
    final snapshot = await _firestore
        .collection('auth_links')
        .doc(authUid)
        .get();
    final data = snapshot.data();
    if (snapshot.exists) {
      if (data == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-auth-link',
          message: 'O vínculo de autenticação existe, mas não possui dados.',
        );
      }
      final link = AuthLink.fromMap(authUid, data);
      final personId = PersonIdentityResolver.resolve(
        authUid: authUid,
        linkedPersonId: link.personId,
      );
      if (link.personId.trim().isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-auth-link',
          message: 'O vínculo de autenticação não possui um personId válido.',
        );
      }
      return personId;
    }
    return PersonIdentityResolver.resolve(authUid: authUid);
  }
}
