import 'profile_gateway.dart';

/// Offline mock for development — stores profile in memory.
class MockProfileGateway implements ProfileGateway {
  UserProfile? _stored;

  @override
  Future<UserProfile?> loadProfile(String userId) async {
    return _stored;
  }

  @override
  Future<void> saveProfile(String userId, UserProfile profile) async {
    _stored = profile;
  }

  @override
  Future<void> deleteProfile(String userId) async {
    _stored = null;
  }
}
