import 'reflections_gateway.dart';

/// In-memory mock for development.
class MockReflectionsGateway implements ReflectionsGateway {
  final List<Reflection> _reflections = [];
  int _nextId = 1;

  MockReflectionsGateway() {
    // Seed a few sample reflections
    _reflections.addAll([
      Reflection(
        id: 'ref_seed_1',
        actionId: 'sample_1',
        actionTitle: '10-minute meditation',
        lane: 'mind',
        note: 'Felt really calm afterwards. Mind kept wandering but I brought it back each time.',
        prompt: 'What did your mind reveal to you?',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Reflection(
        id: 'ref_seed_2',
        actionId: 'sample_2',
        actionTitle: '30-minute workout',
        lane: 'body',
        note: 'Pushed through the last set. Legs are sore but feeling strong.',
        prompt: 'Where did you feel the breakthrough?',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Reflection(
        id: 'ref_seed_3',
        actionId: 'sample_4',
        actionTitle: 'Reach out to one person',
        lane: 'social',
        note: 'Called my cousin. We talked for 20 minutes. Felt good to reconnect.',
        prompt: 'Who did you connect with and how did it feel?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);
  }

  @override
  Future<List<Reflection>> loadReflections(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.of(_reflections)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Reflection>> loadReflectionsByLane(String userId, String lane) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _reflections
        .where((r) => r.lane == lane)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Reflection> saveReflection(String userId, {
    required String actionId,
    required String actionTitle,
    required String lane,
    required String note,
    required String prompt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final reflection = Reflection(
      id: 'ref_${_nextId++}',
      actionId: actionId,
      actionTitle: actionTitle,
      lane: lane,
      note: note,
      prompt: prompt,
      createdAt: DateTime.now(),
    );
    _reflections.add(reflection);
    return reflection;
  }

  @override
  Future<void> deleteReflection(String userId, String reflectionId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _reflections.removeWhere((r) => r.id == reflectionId);
  }
}
