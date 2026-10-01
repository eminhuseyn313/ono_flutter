import 'actions_gateway.dart';
import 'blueprint_gateway.dart';

/// Offline mock for development — generates today's actions from the
/// saved blueprint and tracks completion in memory.
class MockActionsGateway implements ActionsGateway {
  final List<DailyAction> _actions = [];
  int _streak = 0;
  bool _initialised = false;

  /// Seed today's actions from a blueprint (call once after blueprint loads).
  void seedFromBlueprint(Blueprint blueprint) {
    _actions.clear();
    var i = 0;
    for (final action in blueprint.allActions) {
      _actions.add(DailyAction(
        id: action.id,
        title: action.title,
        subtitle: action.subtitle,
        lane: action.laneId,
        completed: false,
        orderIndex: i++,
      ));
    }
    _initialised = true;
  }

  @override
  Future<List<DailyAction>> loadTodayActions(String userId) async {
    if (!_initialised) {
      // Return sample actions if no blueprint loaded yet
      return const [
        DailyAction(
          id: 'sample_1',
          title: '10-minute meditation',
          lane: 'mind',
          orderIndex: 0,
        ),
        DailyAction(
          id: 'sample_2',
          title: '30-minute workout',
          lane: 'body',
          orderIndex: 1,
        ),
        DailyAction(
          id: 'sample_3',
          title: 'Read 15 pages',
          lane: 'skill',
          orderIndex: 2,
        ),
        DailyAction(
          id: 'sample_4',
          title: 'Reach out to one person',
          lane: 'social',
          orderIndex: 3,
        ),
      ];
    }
    return List.of(_actions);
  }

  @override
  Future<void> toggleAction(
      String userId, String actionId, bool completed) async {
    final idx = _actions.indexWhere((a) => a.id == actionId);
    if (idx != -1) {
      _actions[idx] = _actions[idx].copyWith(completed: completed);
    }

    // Update streak if all done
    if (_actions.every((a) => a.completed)) {
      _streak++;
    }
  }

  @override
  Future<int> loadStreak(String userId) async => _streak;

  @override
  Future<List<DayRecord>> loadHistory(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) async {
    // Return some sample history for chart testing
    final days = to.difference(from).inDays;
    return List.generate(days, (i) {
      final date = from.add(Duration(days: i));
      final completed = (i % 3 == 0) ? 4 : (i % 2 == 0) ? 3 : 2;
      return DayRecord(date: date, completedCount: completed, totalCount: 4);
    });
  }
}
