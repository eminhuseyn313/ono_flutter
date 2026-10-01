import '../models/time_capsule.dart';

abstract class TimeCapsuleGateway {
  Future<List<TimeCapsule>> loadCapsules(String userId);

  Future<TimeCapsule> createCapsule(
    String userId, {
    required String message,
    String? lane,
    required DateTime unlockAt,
    String? mood,
  });

  Future<void> openCapsule(String userId, String capsuleId);

  Future<void> deleteCapsule(String userId, String capsuleId);
}
