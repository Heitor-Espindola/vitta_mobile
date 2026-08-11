import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';

class FirebaseVaccinationRepository implements VaccinationRepository {
  FirebaseVaccinationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<VaccinationRecord>> getRecordsByChild(String childId) async {
    final snapshot = await _firestore
        .collection('vaccination_records')
        .where('childId', isEqualTo: childId)
        .get();

    return snapshot.docs.map((document) {
      return VaccinationRecord.fromMap({...document.data(), 'id': document.id});
    }).toList();
  }

  @override
  Future<List<VaccinationRecord>> getRecordsByResponsible(
    String responsibleId,
  ) async {
    final snapshot = await _firestore
        .collection('vaccination_records')
        .where('responsibleId', isEqualTo: responsibleId)
        .get();

    return snapshot.docs.map((document) {
      return VaccinationRecord.fromMap({...document.data(), 'id': document.id});
    }).toList();
  }

  @override
  Future<List<VaccinationRecord>> getRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) async {
    if (personId != responsibleId) return getRecordsByChild(personId);
    final records = await getRecordsByResponsible(responsibleId);
    return records.where((record) {
      final recordPersonId = record.personId;
      return recordPersonId.isEmpty || recordPersonId == personId;
    }).toList();
  }

  @override
  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) {
    return _firestore
        .collection('vaccination_records')
        .where('responsibleId', isEqualTo: responsibleId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => VaccinationRecord.fromMap({
                  ...document.data(),
                  'id': document.id,
                }),
              )
              .where((record) {
                final recordPersonId = record.personId;
                if (personId == responsibleId) {
                  return recordPersonId.isEmpty || recordPersonId == personId;
                }
                return recordPersonId == personId;
              })
              .toList(growable: false),
        );
  }

  @override
  Future<List<Vaccine>> getVaccines() async {
    final snapshot = await _firestore.collection('vaccines').get();

    return snapshot.docs.map((document) {
      return Vaccine.fromMap({...document.data(), 'id': document.id});
    }).toList();
  }
}
