import '../models/personal_system.dart';

abstract class PersonalSystemGateway {
  Future<PersonalSystemState> load(String userId);
  Future<void> save(String userId, PersonalSystemState state);

  /// Deletes everything stored for [userId], everywhere this gateway keeps it.
  Future<void> erase(String userId);

  /// Whether a copy also lives in the cloud.
  bool get syncsToCloud;

  /// Merges [state] with the cloud copy and uploads the result. Returns the
  /// merged state when it differs from [state] (changes from another
  /// device), else null. Gateways without a cloud copy return null.
  Future<PersonalSystemState?> sync(String userId, PersonalSystemState state);
}
