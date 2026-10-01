import '../models/brotherhood.dart';
import 'brotherhood_gateway.dart';

class MockBrotherhoodGateway implements BrotherhoodGateway {
  final _now = DateTime.now();

  late final List<BrotherhoodMember> _members = [
    BrotherhoodMember(
      id: 'user_self',
      anonymousName: 'Warrior #1',
      avatarEmoji: '⚔️',
      streakDays: 12,
      completionRate: 0.78,
      isCurrentUser: true,
      lastActiveAt: _now.subtract(const Duration(minutes: 15)),
      roleModelId: 'user_phoenix',
    ),
    BrotherhoodMember(
      id: 'user_shadow',
      anonymousName: 'Shadow #2',
      avatarEmoji: '🥷',
      streakDays: 8,
      completionRate: 0.65,
      isCurrentUser: false,
      lastActiveAt: _now.subtract(const Duration(hours: 2)),
    ),
    BrotherhoodMember(
      id: 'user_phoenix',
      anonymousName: 'Phoenix #3',
      avatarEmoji: '🦅',
      streakDays: 21,
      completionRate: 0.92,
      isCurrentUser: false,
      lastActiveAt: _now.subtract(const Duration(minutes: 45)),
    ),
    BrotherhoodMember(
      id: 'user_storm',
      anonymousName: 'Storm #4',
      avatarEmoji: '⚡',
      streakDays: 3,
      completionRate: 0.45,
      isCurrentUser: false,
      lastActiveAt: _now.subtract(const Duration(hours: 8)),
    ),
  ];

  late final BrotherhoodSquad _squad = BrotherhoodSquad(
    id: 'squad_titan',
    name: 'Squad Titan',
    members: _members,
    createdAt: _now.subtract(const Duration(days: 14)),
    journeyId: 'journey_discipline',
    weekNumber: 3,
  );

  late final List<SquadMessage> _messages = [
    SquadMessage(
      id: 'msg_1',
      senderId: 'user_phoenix',
      anonymousName: 'Phoenix #3',
      message: 'Just hit a 21-day streak! Stay consistent, brothers.',
      timestamp: _now.subtract(const Duration(hours: 1)),
      type: SquadMessageType.milestone,
    ),
    SquadMessage(
      id: 'msg_2',
      senderId: 'user_self',
      anonymousName: 'Warrior #1',
      message: 'Sent encouragement to Storm #4 💪',
      timestamp: _now.subtract(const Duration(hours: 3)),
      type: SquadMessageType.encouragement,
    ),
    SquadMessage(
      id: 'msg_3',
      senderId: 'user_shadow',
      anonymousName: 'Shadow #2',
      message: 'Completed the morning routine challenge!',
      timestamp: _now.subtract(const Duration(hours: 5)),
      type: SquadMessageType.challengeComplete,
    ),
    SquadMessage(
      id: 'msg_4',
      senderId: 'user_storm',
      anonymousName: 'Storm #4',
      message: 'Back on track today. Not giving up.',
      timestamp: _now.subtract(const Duration(hours: 7)),
      type: SquadMessageType.encouragement,
    ),
    SquadMessage(
      id: 'msg_5',
      senderId: 'user_phoenix',
      anonymousName: 'Phoenix #3',
      message: 'Sent encouragement to Storm #4 💪',
      timestamp: _now.subtract(const Duration(hours: 10)),
      type: SquadMessageType.encouragement,
    ),
    SquadMessage(
      id: 'msg_6',
      senderId: 'user_shadow',
      anonymousName: 'Shadow #2',
      message: 'Joined Squad Titan. Let\'s grow together.',
      timestamp: _now.subtract(const Duration(days: 14)),
      type: SquadMessageType.joined,
    ),
    SquadMessage(
      id: 'msg_7',
      senderId: 'user_self',
      anonymousName: 'Warrior #1',
      message: 'Week 2 done. Feeling the momentum.',
      timestamp: _now.subtract(const Duration(days: 1)),
      type: SquadMessageType.milestone,
    ),
  ];

  late final SquadChallenge _challenge = SquadChallenge(
    id: 'challenge_1',
    title: 'Full Spectrum',
    description: 'Complete all 4 lanes for 3 consecutive days',
    targetCompletions: 12,
    currentCompletions: 7,
    deadline: _now.add(const Duration(days: 2, hours: 6)),
    reward: 'Squad Titan badge + bonus XP for all members',
  );

  @override
  Future<BrotherhoodSquad> loadSquad() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _squad;
  }

  @override
  Future<List<SquadMessage>> loadSquadMessages() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return List.from(_messages);
  }

  @override
  Future<void> sendEncouragement(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final target = _members.firstWhere((m) => m.id == memberId);
    _messages.insert(
      0,
      SquadMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'user_self',
        anonymousName: 'Warrior #1',
        message: 'Sent encouragement to ${target.anonymousName} 💪',
        timestamp: DateTime.now(),
        type: SquadMessageType.encouragement,
      ),
    );
  }

  @override
  Future<BrotherhoodSquad> joinSquad(String journeyId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _squad;
  }

  @override
  Future<void> leaveSquad() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<SquadChallenge> loadSquadChallenge() async {
    await Future.delayed(const Duration(milliseconds: 170));
    return _challenge;
  }

  @override
  Future<void> completeSquadChallenge() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
