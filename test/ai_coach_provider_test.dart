import 'package:flutter_test/flutter_test.dart';

import 'package:ono/gateways/ai_coach_gateway.dart';
import 'package:ono/models/ai_coach.dart';
import 'package:ono/providers/ai_coach_provider.dart';

// ---------------------------------------------------------------------------
// Mock gateway
// ---------------------------------------------------------------------------
class MockAiCoachGateway implements AiCoachGateway {
  CoachData? data;
  Exception? loadError;
  final List<String> markedRead = [];
  final List<String> dismissed = [];
  final List<String> bookmarked = [];
  CoachTone? lastTone;

  @override
  Future<CoachData> loadCoachData() async {
    if (loadError != null) throw loadError!;
    return data!;
  }

  @override
  Future<void> markInsightRead(String insightId) async {
    markedRead.add(insightId);
  }

  @override
  Future<void> dismissInsight(String insightId) async {
    dismissed.add(insightId);
  }

  @override
  Future<void> toggleTipBookmark(String tipId) async {
    bookmarked.add(tipId);
  }

  @override
  Future<void> setPreferredTone(CoachTone tone) async {
    lastTone = tone;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
CoachInsight _insight({
  String id = 'i1',
  InsightType type = InsightType.pattern,
  bool isRead = false,
  bool isDismissed = false,
}) =>
    CoachInsight(
      id: id,
      type: type,
      title: 'Test Insight',
      message: 'Body text',
      createdAt: DateTime(2026, 1, 1),
      isRead: isRead,
      isDismissed: isDismissed,
    );

DailyCoachTip _tip({String id = 't1', bool isBookmarked = false}) =>
    DailyCoachTip(
      id: id,
      title: 'Tip',
      content: 'Tip body',
      lane: 'Mind',
      laneColorValue: 0xFF8B5CF6,
      date: DateTime(2026, 1, 1),
      isBookmarked: isBookmarked,
    );

CoachData _coachData({
  List<CoachInsight>? insights,
  DailyCoachTip? dailyTip,
}) =>
    CoachData(
      insights: insights ?? [_insight()],
      dailyTip: dailyTip ?? _tip(),
      preferredTone: CoachTone.motivational,
      streakDays: 10,
      overallScore: 72.5,
      laneScores: {'Mind': 78, 'Body': 85},
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockAiCoachGateway gateway;
  late AiCoachProvider provider;

  setUp(() {
    gateway = MockAiCoachGateway();
    provider = AiCoachProvider(gateway: gateway);
  });

  tearDown(() => provider.dispose());

  // -- Initial state -------------------------------------------------------

  group('initial state', () {
    test('coachData is null before load', () {
      expect(provider.coachData, isNull);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.activeInsights, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.dailyTip, isNull);
    });
  });

  // -- Load coach data -----------------------------------------------------

  group('loadCoachData', () {
    test('loads data successfully', () async {
      gateway.data = _coachData();

      await provider.loadCoachData();

      expect(provider.coachData, isNotNull);
      expect(provider.coachData!.streakDays, 10);
      expect(provider.coachData!.overallScore, 72.5);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('sets isLoading during fetch', () async {
      gateway.data = _coachData();

      bool wasLoading = false;
      provider.addListener(() {
        if (provider.isLoading) wasLoading = true;
      });

      await provider.loadCoachData();

      expect(wasLoading, true);
      expect(provider.isLoading, false);
    });

    test('load error sets error message', () async {
      gateway.loadError = Exception('network error');

      await provider.loadCoachData();

      expect(provider.coachData, isNull);
      expect(provider.error, isNotNull);
    });
  });

  // -- Active insights & unread count --------------------------------------

  group('activeInsights', () {
    test('filters out dismissed insights', () async {
      gateway.data = _coachData(insights: [
        _insight(id: 'i1', isDismissed: false),
        _insight(id: 'i2', isDismissed: true),
        _insight(id: 'i3', isDismissed: false),
      ]);

      await provider.loadCoachData();

      expect(provider.activeInsights.length, 2);
      expect(provider.activeInsights.map((i) => i.id), ['i1', 'i3']);
    });

    test('unreadCount counts non-read active insights', () async {
      gateway.data = _coachData(insights: [
        _insight(id: 'i1', isRead: false),
        _insight(id: 'i2', isRead: true),
        _insight(id: 'i3', isRead: false, isDismissed: true),
      ]);

      await provider.loadCoachData();

      // i1 unread+active, i2 read+active, i3 unread but dismissed
      expect(provider.unreadCount, 1);
    });
  });

  // -- Mark insight read ---------------------------------------------------

  group('markInsightRead', () {
    test('marks insight as read locally', () async {
      gateway.data = _coachData(insights: [
        _insight(id: 'i1', isRead: false),
      ]);
      await provider.loadCoachData();

      await provider.markInsightRead('i1');

      expect(gateway.markedRead, ['i1']);
      expect(provider.coachData!.insights.first.isRead, true);
      expect(provider.unreadCount, 0);
    });
  });

  // -- Dismiss insight -----------------------------------------------------

  group('dismissInsight', () {
    test('dismisses insight locally', () async {
      gateway.data = _coachData(insights: [
        _insight(id: 'i1'),
        _insight(id: 'i2'),
      ]);
      await provider.loadCoachData();

      await provider.dismissInsight('i1');

      expect(gateway.dismissed, ['i1']);
      expect(provider.activeInsights.length, 1);
      expect(provider.activeInsights.first.id, 'i2');
    });
  });

  // -- Toggle tip bookmark -------------------------------------------------

  group('toggleTipBookmark', () {
    test('toggles bookmark state', () async {
      gateway.data = _coachData(dailyTip: _tip(isBookmarked: false));
      await provider.loadCoachData();

      await provider.toggleTipBookmark();

      expect(gateway.bookmarked, ['t1']);
      expect(provider.dailyTip!.isBookmarked, true);
    });

    test('no-op when dailyTip is null', () async {
      // Don't load — coachData is null
      await provider.toggleTipBookmark();
      expect(gateway.bookmarked, isEmpty);
    });
  });

  // -- Set preferred tone --------------------------------------------------

  group('setPreferredTone', () {
    test('sets tone on gateway', () async {
      gateway.data = _coachData();
      await provider.loadCoachData();

      await provider.setPreferredTone(CoachTone.analytical);

      expect(gateway.lastTone, CoachTone.analytical);
    });
  });

  // -- Model serialization -------------------------------------------------

  group('CoachInsight toJson/fromJson', () {
    test('round-trips correctly', () {
      final original = _insight(id: 'x1', isRead: true);
      final json = original.toJson();
      final restored = CoachInsight.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.isRead, true);
      expect(restored.isDismissed, false);
    });
  });

  group('DailyCoachTip toJson/fromJson', () {
    test('round-trips correctly', () {
      final original = _tip(isBookmarked: true);
      final json = original.toJson();
      final restored = DailyCoachTip.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.isBookmarked, true);
      expect(restored.lane, 'Mind');
    });
  });
}
