abstract interface class PersonIdentityRepository {
  Future<String> resolvePersonId(String authUid);
}
