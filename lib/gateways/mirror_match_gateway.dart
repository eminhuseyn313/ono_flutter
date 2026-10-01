import '../models/mirror_match.dart';

abstract class MirrorMatchGateway {
  Future<MirrorMatchData> loadMatchData();
  Future<MirrorProfile?> findMatch();
  Future<List<MirrorMessage>> loadMessages(String mirrorId);
  Future<MirrorMessage> sendMessage(String mirrorId, String text);
  Future<void> dismissMatch(String mirrorId);
}
