import 'package:vitta_mobile/features/information/domain/models/information_post.dart';

abstract interface class InformationRepository {
  Future<List<InformationPost>> getPosts();
}
