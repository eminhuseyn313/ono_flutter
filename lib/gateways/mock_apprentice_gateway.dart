import '../models/apprentice_mode.dart';
import 'apprentice_gateway.dart';

/// Mock implementation of [ApprenticeGateway] with in-memory storage.
class MockApprenticeGateway implements ApprenticeGateway {
  /// In-memory store: userId -> (lane -> binding).
  final Map<String, Map<String, ApprenticeBinding>> _store = {};

  /// Hardcoded action suggestions per lane.
  static const Map<String, List<String>> _actionsByLane = {
    'mind': [
      'Morning meditation (Marcus Aurelius style)',
      'Journal 3 stoic reflections',
      'Read philosophy for 15 min',
    ],
    'body': [
      'Complete workout routine',
      'Track nutrition for the day',
      '10-min stretching session',
    ],
    'social': [
      'Practice active listening in one conversation',
      'Give genuine compliment to 3 people',
      'Reach out to an old friend',
    ],
    'skill': [
      'Deep work session — 90 min focus block',
      'Learn one new concept in your field',
      'Teach someone what you learned yesterday',
    ],
  };

  @override
  Future<List<ApprenticeBinding>> loadBindings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final userBindings = _store[userId];
    if (userBindings == null) return [];
    return userBindings.values.toList();
  }

  @override
  Future<void> setBinding(String userId, ApprenticeBinding binding) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _store.putIfAbsent(userId, () => {});
    _store[userId]![binding.lane] = binding;
  }

  @override
  Future<void> removeBinding(String userId, String lane) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _store[userId]?.remove(lane);
  }

  @override
  Future<List<String>> getApprenticeActions(
    String userId,
    String lane,
    String roleModelId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _actionsByLane[lane] ?? [];
  }
}
