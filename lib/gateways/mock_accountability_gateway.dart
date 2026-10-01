// gateways/mock_accountability_gateway.dart

import '../models/accountability.dart';
import 'accountability_gateway.dart';

class MockAccountabilityGateway implements AccountabilityGateway {
  final List<AccountabilityPartner> _partners = [
    AccountabilityPartner(
      id: 'partner_1',
      odaCode: 'ONO-KING-4821',
      partnerName: 'Marcus J.',
      partnerAvatar: '\u{1F525}',
      status: PartnerStatus.active,
      sharedStreak: 34,
      longestStreak: 34,
      startedAt: DateTime.now().subtract(const Duration(days: 40)),
      lastCheckInAt: DateTime.now().subtract(const Duration(hours: 3)),
      partnerLevel: 12,
      partnerXp: 3400,
    ),
    AccountabilityPartner(
      id: 'partner_2',
      odaCode: 'ONO-WOLF-7763',
      partnerName: 'Darius K.',
      partnerAvatar: '\u{1F3CB}',
      status: PartnerStatus.active,
      sharedStreak: 7,
      longestStreak: 14,
      startedAt: DateTime.now().subtract(const Duration(days: 10)),
      lastCheckInAt: DateTime.now().subtract(const Duration(hours: 18)),
      partnerLevel: 6,
      partnerXp: 1250,
    ),
    AccountabilityPartner(
      id: 'partner_3',
      odaCode: 'ONO-BEAR-3390',
      partnerName: 'Tyler M.',
      partnerAvatar: '\u{1F4AA}',
      status: PartnerStatus.paused,
      sharedStreak: 0,
      longestStreak: 21,
      startedAt: DateTime.now().subtract(const Duration(days: 60)),
      lastCheckInAt: DateTime.now().subtract(const Duration(days: 12)),
      partnerLevel: 9,
      partnerXp: 2100,
    ),
  ];

  final List<PartnerRequest> _requests = [
    PartnerRequest(
      id: 'req_1',
      fromName: 'Jordan B.',
      fromAvatar: '\u{1F9E0}',
      fromLevel: 8,
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      message: 'Yo, let\'s hold each other accountable on the morning routine grind. I\'m on a 15-day streak rn.',
    ),
    PartnerRequest(
      id: 'req_2',
      fromName: 'Kai R.',
      fromAvatar: '\u{26A1}',
      fromLevel: 4,
      sentAt: DateTime.now().subtract(const Duration(hours: 8)),
      message: 'Looking for someone serious about reading daily. 20 pages minimum. You down?',
    ),
  ];

  final List<SharedProof> _proofs = [
    SharedProof(
      id: 'proof_1',
      partnerId: 'partner_1',
      senderName: 'Marcus J.',
      proofType: ProofType.photo,
      content: 'gym_session_5am.jpg',
      caption: '5 AM chest day. No excuses.',
      sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      isVerified: true,
    ),
    SharedProof(
      id: 'proof_2',
      partnerId: 'partner_1',
      senderName: 'You',
      proofType: ProofType.text,
      content: 'Finished 30 pages of Atomic Habits before 7 AM. Chapter on habit stacking is a game-changer.',
      caption: 'Morning reading done',
      sentAt: DateTime.now().subtract(const Duration(hours: 6)),
      isVerified: true,
    ),
    SharedProof(
      id: 'proof_3',
      partnerId: 'partner_1',
      senderName: 'Marcus J.',
      proofType: ProofType.streak,
      content: '34',
      caption: '34 days straight. We\'re locked in.',
      sentAt: DateTime.now().subtract(const Duration(hours: 8)),
      isVerified: true,
    ),
    SharedProof(
      id: 'proof_4',
      partnerId: 'partner_2',
      senderName: 'Darius K.',
      proofType: ProofType.photo,
      content: 'cold_shower_timer.jpg',
      caption: '3 min cold shower. Brain feels crystal clear.',
      sentAt: DateTime.now().subtract(const Duration(hours: 20)),
      isVerified: true,
    ),
    SharedProof(
      id: 'proof_5',
      partnerId: 'partner_2',
      senderName: 'You',
      proofType: ProofType.text,
      content: 'Meal prepped for the entire week. 6 containers ready. No junk food in the house.',
      caption: 'Sunday prep complete',
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
      isVerified: true,
    ),
    SharedProof(
      id: 'proof_6',
      partnerId: 'partner_2',
      senderName: 'Darius K.',
      proofType: ProofType.streak,
      content: '7',
      caption: 'One week down. Building momentum.',
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      isVerified: false,
    ),
  ];

  final List<DailyCheckIn> _checkIns = [
    DailyCheckIn(
      id: 'checkin_1',
      partnerId: 'partner_1',
      mood: CheckInMood.fired,
      message: 'Hit a PR on deadlift today. 315 lbs. Reading is on track too. Let\'s keep this energy.',
      actionsCompleted: 5,
      streakDay: 34,
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      partnerResponse: 'Beast mode bro. I did 275 today, catching up to you. See you at 5 AM.',
    ),
    DailyCheckIn(
      id: 'checkin_2',
      partnerId: 'partner_1',
      mood: CheckInMood.steady,
      message: 'Solid day. Got the workout in, read my pages, meditated for 10 mins. Nothing crazy but consistent.',
      actionsCompleted: 4,
      streakDay: 33,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      partnerResponse: 'Consistency > intensity. That\'s the play.',
    ),
    DailyCheckIn(
      id: 'checkin_3',
      partnerId: 'partner_2',
      mood: CheckInMood.steady,
      message: 'Did cold shower, journaling, and a 30 min run. Skipped the reading though, ran out of time.',
      actionsCompleted: 3,
      streakDay: 7,
      sentAt: DateTime.now().subtract(const Duration(hours: 18)),
      partnerResponse: null,
    ),
    DailyCheckIn(
      id: 'checkin_4',
      partnerId: 'partner_2',
      mood: CheckInMood.struggling,
      message: 'Rough day. Only got the workout in. Work was intense and I crashed after dinner. Back at it tomorrow.',
      actionsCompleted: 1,
      streakDay: 6,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 16)),
      partnerResponse: 'We all have those days. The fact you still trained says everything. Reset tomorrow.',
    ),
    DailyCheckIn(
      id: 'checkin_5',
      partnerId: 'partner_1',
      mood: CheckInMood.fired,
      message: 'Woke up at 4:30, crushed a fasted workout, cold shower, read 40 pages. Feeling unstoppable.',
      actionsCompleted: 6,
      streakDay: 32,
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      partnerResponse: 'You\'re a machine. I need to step it up.',
    ),
  ];

  @override
  Future<List<AccountabilityPartner>> loadPartners() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_partners);
  }

  @override
  Future<List<PartnerRequest>> loadRequests() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_requests);
  }

  @override
  Future<List<SharedProof>> loadProofs(String partnerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(
      _proofs.where((p) => p.partnerId == partnerId),
    );
  }

  @override
  Future<List<DailyCheckIn>> loadCheckIns(String partnerId) async {
    await Future.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(
      _checkIns.where((c) => c.partnerId == partnerId),
    );
  }

  @override
  Future<AccountabilityStats> loadStats() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const AccountabilityStats(
      totalPartners: 3,
      activePartners: 2,
      longestStreak: 34,
      totalCheckIns: 47,
      totalProofsShared: 28,
      averageMood: 3.2,
    );
  }

  @override
  Future<String> sendRequest(String code) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return 'ONO-HAWK-9914';
  }

  @override
  Future<AccountabilityPartner> acceptRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final request = _requests.firstWhere((r) => r.id == id);
    _requests.removeWhere((r) => r.id == id);
    final newPartner = AccountabilityPartner(
      id: 'partner_new_${DateTime.now().millisecondsSinceEpoch}',
      odaCode: 'ONO-NEW-0001',
      partnerName: request.fromName,
      partnerAvatar: request.fromAvatar,
      status: PartnerStatus.active,
      sharedStreak: 0,
      longestStreak: 0,
      startedAt: DateTime.now(),
      lastCheckInAt: null,
      partnerLevel: request.fromLevel,
      partnerXp: request.fromLevel * 200,
    );
    _partners.add(newPartner);
    return newPartner;
  }

  @override
  Future<void> declineRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 180));
    _requests.removeWhere((r) => r.id == id);
  }

  @override
  Future<SharedProof> sendProof(String partnerId, SharedProof proof) async {
    await Future.delayed(const Duration(milliseconds: 220));
    final sent = proof.copyWith(
      id: 'proof_new_${DateTime.now().millisecondsSinceEpoch}',
      sentAt: DateTime.now(),
    );
    _proofs.insert(0, sent);
    return sent;
  }

  @override
  Future<DailyCheckIn> sendCheckIn(String partnerId, DailyCheckIn checkIn) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sent = checkIn.copyWith(
      id: 'checkin_new_${DateTime.now().millisecondsSinceEpoch}',
      sentAt: DateTime.now(),
    );
    _checkIns.insert(0, sent);
    return sent;
  }

  @override
  Future<AccountabilityPartner> pausePartnership(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _partners.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Partner not found');
    final current = _partners[index];
    final newStatus = current.status == PartnerStatus.paused
        ? PartnerStatus.active
        : PartnerStatus.paused;
    final updated = current.copyWith(
      status: newStatus,
      sharedStreak: newStatus == PartnerStatus.paused ? 0 : current.sharedStreak,
    );
    _partners[index] = updated;
    return updated;
  }

  @override
  Future<void> endPartnership(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _partners.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Partner not found');
    _partners[index] = _partners[index].copyWith(status: PartnerStatus.ended);
  }
}
