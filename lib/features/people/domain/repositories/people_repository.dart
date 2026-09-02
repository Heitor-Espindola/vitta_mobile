import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';

abstract interface class PeopleRepository {
  Future<List<AppUser>> getAvailablePeople(String guardianId);

  Future<List<FamilyMember>> getFamilyMembers(String currentPersonId);

  Future<AppUser> createDependent({
    required String guardianId,
    required String name,
    required DateTime birthDate,
    required String relationship,
    required String cpf,
  });
}
