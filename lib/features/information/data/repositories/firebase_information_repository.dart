import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vitta_mobile/features/information/domain/models/information_post.dart';
import 'package:vitta_mobile/features/information/domain/repositories/information_repository.dart';

class FirebaseInformationRepository implements InformationRepository {
  FirebaseInformationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<InformationPost>> getPosts() async {
    final snapshot = await _firestore.collection('information_posts').get();

    return snapshot.docs.map((document) {
      return InformationPost.fromMap({...document.data(), 'id': document.id});
    }).toList();
  }
}
