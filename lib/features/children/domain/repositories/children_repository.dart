import 'package:vitta_mobile/features/children/domain/models/child.dart';

abstract interface class ChildrenRepository {
  Future<List<Child>> getChildrenByResponsible(String responsibleId);

  Future<Child> createChild(Child child);

  Future<void> updateChild(Child child);

  Future<void> deleteChild(String childId);
}
