import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vitta_mobile/features/children/domain/models/child.dart';
import 'package:vitta_mobile/features/children/domain/repositories/children_repository.dart';

class FirebaseChildrenRepository implements ChildrenRepository {
  FirebaseChildrenRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _children =>
      _firestore.collection('children');

  @override
  Future<Child> createChild(Child child) async {
    final now = DateTime.now();
    final document = _children.doc();
    final childToCreate = child.copyWith(
      id: document.id,
      createdAt: child.createdAt ?? now,
      updatedAt: now,
    );

    await document.set(childToCreate.toMap());
    return childToCreate;
  }

  @override
  Future<void> deleteChild(String childId) {
    return _children.doc(childId).delete();
  }

  @override
  Future<List<Child>> getChildrenByResponsible(String responsibleId) async {
    final snapshot = await _children
        .where('responsibleId', isEqualTo: responsibleId)
        .get();

    return snapshot.docs.map((document) {
      return Child.fromMap({...document.data(), 'id': document.id});
    }).toList();
  }

  @override
  Future<void> updateChild(Child child) {
    return _children.doc(child.id).update({
      'name': child.name,
      'birthDate': child.birthDate,
      'gender': child.gender,
      'updatedAt': DateTime.now(),
    });
  }
}
