import 'package:vitta_mobile/core/config/app_environment.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/data/repositories/sql_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/data/repositories/firebase_people_repository.dart';
import 'package:vitta_mobile/features/people/data/repositories/sql_people_repository.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/sql_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';

abstract final class DomainRepositoryFactory {
  static AuthRepository auth() => AppEnvironment.useLegacyFirestoreDomain
      ? FirebaseAuthRepository()
      : SqlAuthRepository();

  static PeopleRepository people() => AppEnvironment.useLegacyFirestoreDomain
      ? FirebasePeopleRepository()
      : SqlPeopleRepository();

  static VaccinationRepository vaccination() =>
      AppEnvironment.useLegacyFirestoreDomain
      ? FirebaseVaccinationRepository()
      : SqlVaccinationRepository();
}
