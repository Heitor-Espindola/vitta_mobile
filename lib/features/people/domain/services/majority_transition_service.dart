import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

enum MajorityTransitionState { unknown, minor, newlyIndependent, independent }

abstract final class MajorityTransitionService {
  static MajorityTransitionState state(AppUser person, {DateTime? now}) {
    final majorityAt = person.effectiveMajorityAt;
    if (majorityAt == null) return MajorityTransitionState.unknown;
    final reference = now ?? DateTime.now();
    if (reference.isBefore(majorityAt)) return MajorityTransitionState.minor;
    if (reference.difference(majorityAt).inDays <= 30) {
      return MajorityTransitionState.newlyIndependent;
    }
    return MajorityTransitionState.independent;
  }
}
