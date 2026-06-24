import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';

abstract interface class VaccinationRepository {
  Future<List<Vaccine>> getVaccines();

  Future<List<VaccinationRecord>> getRecordsByChild(String childId);

  Future<List<VaccinationRecord>> getRecordsByResponsible(String responsibleId);
}
