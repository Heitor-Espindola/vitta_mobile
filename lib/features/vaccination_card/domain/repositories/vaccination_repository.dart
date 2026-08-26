import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';

abstract interface class VaccinationRepository {
  Future<List<Vaccine>> getVaccines();

  Future<List<VaccinationRecord>> getRecordsByChild(String childId);

  Future<List<VaccinationRecord>> getRecordsByResponsible(String responsibleId);

  Future<List<VaccinationRecord>> getRecordsByPerson({
    required String personId,
    required String responsibleId,
  });

  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  });

  Stream<List<VaccinationRecord>> watchPatientRecords(String patientId) =>
      watchRecordsByPerson(personId: patientId, responsibleId: patientId);
}
