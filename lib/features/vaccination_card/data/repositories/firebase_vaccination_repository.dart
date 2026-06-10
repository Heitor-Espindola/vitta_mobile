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
  Future<List<Vaccine>> getVaccines() async {
    final snapshot = await _firestore.collection('vaccines').get();

    return snapshot.docs.map((document) {
      return Vaccine.fromMap({...document.data(), 'id': document.id});
    }).toList();
  }
}
