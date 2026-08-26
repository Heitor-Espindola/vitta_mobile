import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

abstract interface class PeopleRepository {
  Future<List<AppUser>> getAvailablePeople(String guardianId);

  Future<AppUser> createDependent({
    required String guardianId,
    required String name,
    required DateTime birthDate,
    required String relationship,
    required String cpf,
  });
}
