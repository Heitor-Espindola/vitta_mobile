abstract final class PersonIdentityResolver {
  static String resolve({required String authUid, String? linkedPersonId}) {
    final linked = linkedPersonId?.trim();
    return linked == null || linked.isEmpty ? authUid : linked;
  }
}
