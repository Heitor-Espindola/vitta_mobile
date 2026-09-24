import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:vitta_mobile/dataconnect_generated/mobile_connector.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';

class SqlVaccinationRepository implements VaccinationRepository {
  SqlVaccinationRepository({MobileConnectorConnector? connector})
    : _connector = connector ?? MobileConnectorConnector.instance;

  final MobileConnectorConnector _connector;

  @override
  Future<List<Vaccine>> getVaccines() async {
    final result = await _connector.getMobileVaccines().execute(
      fetchPolicy: QueryFetchPolicy.serverOnly,
    );
    return result.data.vaccines
        .map(
          (row) => Vaccine(
            id: row.id,
            name: row.name,
            shortName: row.shortName,
            description: row.description,
            recommendedAge: row.recommendedAge,
            doseCount: row.requiredDoses,
            intervalDays: row.intervalDays,
            prevents: row.prevents ?? const [],
            targetGroups: row.targetGroups ?? const [],
            doseSchedule: _objectList(row.doseSchedule?.value),
            expectedReactions: row.expectedReactions ?? const [],
            warningSigns: row.warningSigns ?? const [],
            contraindications: row.contraindications ?? const [],
            sourceName: row.sourceName,
            sourceUrl: row.sourceUrl,
            sourceUpdatedAt: row.sourceUpdatedAt?.toDateTime(),
            calendarVersion: row.calendarVersion,
            active: row.active,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<VaccinationRecord>> getRecordsByChild(String childId) =>
      _getRecords(childId);

  @override
  Future<List<VaccinationRecord>> getRecordsByResponsible(
    String responsibleId,
  ) => _getRecords(responsibleId);

  @override
  Future<List<VaccinationRecord>> getRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) => _getRecords(personId);

  @override
  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) => Stream.fromFuture(_getRecords(personId));

  @override
  Stream<List<VaccinationRecord>> watchPatientRecords(String patientId) =>
      Stream.fromFuture(_getRecords(patientId));

  Future<List<VaccinationRecord>> _getRecords(String patientId) async {
    final result = await _connector
        .getAccessiblePatientVaccinations(patientId: patientId)
        .execute(fetchPolicy: QueryFetchPolicy.serverOnly);
    return result.data.applications
        .where((row) => row.voidedAt == null)
        .map(
          (row) => VaccinationRecord(
            id: row.id,
            patientId: patientId,
            vaccineId: row.vaccine?.id,
            vaccineName: row.vaccineNameSnapshot,
            doseLabel: row.doseLabel ?? '',
            doseNumber: row.doseNumber,
            appliedAt: row.applicationDate.toDateTime(),
            nextDoseAt: row.nextDoseAt?.toDateTime(),
            lot: row.lotSnapshot ?? row.batch?.batchCode,
            manufacturer: row.manufacturerSnapshot ?? row.batch?.manufacturer,
            facilityId: row.ubs?.id,
            facilityName: row.facilityNameSnapshot,
            professionalUid: row.professionalNameSnapshot,
            notes: row.notes,
            source: row.source,
          ),
        )
        .toList(growable: false);
  }
}

List<Object?> _objectList(Object? value) =>
    value is List ? List<Object?>.unmodifiable(value) : const <Object?>[];
