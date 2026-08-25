import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitta_mobile/features/people/data/repositories/firebase_person_identity_repository.dart';
import 'package:vitta_mobile/features/people/domain/repositories/person_identity_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';

class FirebaseVaccinationRepository implements VaccinationRepository {
  FirebaseVaccinationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PersonIdentityRepository? identityRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _identityRepository =
           identityRepository ??
           FirebasePersonIdentityRepository(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PersonIdentityRepository _identityRepository;

  Query<Map<String, dynamic>> _patientQuery(String field, String personId) =>
      _firestore
          .collection('vaccination_records')
          .where(field, isEqualTo: personId)
          .orderBy('appliedAt', descending: true);

  List<VaccinationRecord> _records(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs
      .map(VaccinationRecord.fromFirestore)
      .toList(growable: false);

  @override
  Future<List<VaccinationRecord>> getRecordsByChild(String childId) async =>
      _records(await _patientQuery('patientId', childId).get());

  @override
  Future<List<VaccinationRecord>> getRecordsByResponsible(
    String responsibleId,
  ) => _getCompatibleRecords(responsibleId, responsibleId);

  @override
  Future<List<VaccinationRecord>> getRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) => personId == responsibleId
      ? _getCompatibleRecords(personId, responsibleId)
      : getRecordsByChild(personId);

  Future<List<VaccinationRecord>> _getCompatibleRecords(
    String personId,
    String legacyAuthUid,
  ) async {
    final snapshots = await Future.wait([
      _patientQuery('patientId', personId).get(),
      _patientQuery('patientUid', legacyAuthUid).get(),
    ]);
    return _merge(_records(snapshots[0]), _records(snapshots[1]));
  }

  @override
  Stream<List<VaccinationRecord>> watchPatientRecords(String patientId) async* {
    final authUid = _auth.currentUser?.uid;
    if (authUid == null) {
      throw StateError('A carteira pessoal exige uma sessão autenticada.');
    }
    final currentPersonId = await _identityRepository.resolvePersonId(authUid);
    if (currentPersonId != patientId) {
      throw StateError('A carteira pessoal exige a identidade autenticada.');
    }
    yield* _mergeStreams(
      _patientQuery('patientId', patientId).snapshots().map(_records),
      _patientQuery('patientUid', authUid).snapshots().map(_records),
    );
  }

  @override
  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) => personId == responsibleId
      ? watchPatientRecords(personId)
      : _patientQuery('patientId', personId).snapshots().map(_records);

  Stream<List<VaccinationRecord>> _mergeStreams(
    Stream<List<VaccinationRecord>> current,
    Stream<List<VaccinationRecord>> legacy,
  ) {
    late StreamController<List<VaccinationRecord>> controller;
    StreamSubscription<List<VaccinationRecord>>? currentSubscription;
    StreamSubscription<List<VaccinationRecord>>? legacySubscription;
    var currentRecords = const <VaccinationRecord>[];
    var legacyRecords = const <VaccinationRecord>[];
    void emit() => controller.add(_merge(currentRecords, legacyRecords));
    controller = StreamController<List<VaccinationRecord>>(
      onListen: () {
        currentSubscription = current.listen((records) {
          currentRecords = records;
          emit();
        }, onError: controller.addError);
        legacySubscription = legacy.listen((records) {
          legacyRecords = records;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await currentSubscription?.cancel();
        await legacySubscription?.cancel();
      },
    );
    return controller.stream;
  }

  List<VaccinationRecord> _merge(
    Iterable<VaccinationRecord> current,
    Iterable<VaccinationRecord> legacy,
  ) {
    final byId = <String, VaccinationRecord>{};
    for (final record in [...current, ...legacy]) {
      byId[record.id] = record;
    }
    final result = byId.values.toList()
      ..sort((a, b) {
        final aDate = a.effectiveAppliedAt ?? a.createdAt;
        final bDate = b.effectiveAppliedAt ?? b.createdAt;
        if (aDate == null) return bDate == null ? 0 : 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    return result;
  }

  @override
  Future<List<Vaccine>> getVaccines() async {
    final snapshot = await _firestore.collection('vaccines').get();
    return snapshot.docs
        .map((document) {
          return Vaccine.fromMap({...document.data(), 'id': document.id});
        })
        .where((vaccine) => vaccine.active)
        .toList(growable: false);
  }
}
