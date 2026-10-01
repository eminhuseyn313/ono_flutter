import '../models/brotherhood.dart';

abstract class BrotherhoodGateway {
  Future<BrotherhoodSquad> loadSquad();
  Future<List<SquadMessage>> loadSquadMessages();
  Future<void> sendEncouragement(String memberId);
  Future<BrotherhoodSquad> joinSquad(String journeyId);
  Future<void> leaveSquad();
  Future<SquadChallenge> loadSquadChallenge();
  Future<void> completeSquadChallenge();
}
