import 'package:vitta_mobile/features/people/domain/models/relationship.dart';

abstract interface class RelationshipVerificationService {
  Future<RelationshipStatus> requestVerification(
    PersonRelationship relationship,
  );
}

/// Protótipo honesto: solicita análise manual e nunca concede acesso sozinho.
class ManualRelationshipVerificationService
    implements RelationshipVerificationService {
  const ManualRelationshipVerificationService();

  @override
  Future<RelationshipStatus> requestVerification(
    PersonRelationship relationship,
  ) async => RelationshipStatus.pending;
}
