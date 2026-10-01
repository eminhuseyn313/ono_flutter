import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gateways/monk_mode_gateway.dart';
import '../models/monk_session.dart';

/// Where the user is in a Monk Mode run.
enum MonkSessionPhase { idle, active, completed }

/// Which part of the 4-4-4 breathing cycle is currently playing.
/// (The canonical enum + timing constants live with the widget that
/// actually drives the animation — see `widgets/breathing_circle.dart`.)
enum BreathPhase { inhale, hold, exhale }

/// One full breath cycle, in seconds, split inhale/hold/exhale.
const int kBreathPhaseSeconds = 4;
const int kBreathCycleSeconds = kBreathPhaseSeconds * 3;

/// Duration chips offered on the setup screen, in minutes.
const List<int> kMonkDurationOptions = [2, 5, 10, 15, 20, 30];

/// ChangeNotifier driving the Monk Mode experience: duration selection,
/// the live countdown + breathing cycle, and the post-session summary.
class MonkModeProvider extends ChangeNotifier {
  final MonkModeGateway _gateway;
  String? _userId;

  /// Fired once a session (completed or interrupted) is persisted.
  /// Wire this up where the app composes providers, e.g.:
  ///
  /// ```dart
  /// MonkModeProvider(
  ///   gateway: MockMonkModeGateway(),
  ///   onSessionComplete: (session) {
  ///     if (!session.wasInterrupted) {
  ///       // Feed completed focus time into the Mind lane.
  ///       context.read<ProgressProvider>().recordMindLaneSession(session);
  ///     }
  ///   },
  /// )
  /// ```
  ///
  /// so a completed Monk Mode session bumps Mind lane progress without
  /// this provider needing a direct dependency on [ProgressProvider].
  final void Function(MonkSession session)? onSessionComplete;

  MonkModeProvider({
    required MonkModeGateway gateway,
    this.onSessionComplete,
  }) : _gateway = gateway;

  // ---- Loaded data ---------------------------------------------------
  MonkModeStats stats = MonkModeStats.empty;
  List<MonkSession> history = const [];
  bool isLoading = false;

  // ---- Session state ---------------------------------------------------
  MonkSessionPhase phase = MonkSessionPhase.idle;
  int selectedMinutes = 10;

  Duration _totalDuration = Duration.zero;
  Duration remaining = Duration.zero;

  /// Completed inhale-hold-exhale cycles this session. The
  /// [BreathingCircle] widget owns the actual animation timing and
  /// calls [registerBreathCycle] whenever it finishes one.
  int breathCycles = 0;

  Timer? _timer;
  MonkSession? lastCompletedSession;
  bool _saving = false;

  /// Set by the screen right before it pops/backgrounds due to exit
  /// friction, so callers can show the right copy.
  bool get isActive => phase == MonkSessionPhase.active;

  double get progress {
    if (_totalDuration.inSeconds == 0) return 0;
    final elapsed = _totalDuration.inSeconds - remaining.inSeconds;
    return (elapsed / _totalDuration.inSeconds).clamp(0.0, 1.0);
  }

  String get remainingLabel {
    final m = remaining.inMinutes.toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Copy shown by the exit-friction overlay.
  String get exitFrictionMessage {
    final remainingMinutes = (remaining.inSeconds / 60).ceil();
    return 'You committed to $selectedMinutes minutes. '
        '$remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'} remain. '
        'The flame is still burning.';
  }

  // ---- Lifecycle ---------------------------------------------------

  Future<void> loadInitialData(String userId) async {
    _userId = userId;
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _gateway.loadStats(userId),
        _gateway.loadHistory(userId),
      ]);
      stats = results[0] as MonkModeStats;
      history = results[1] as List<MonkSession>;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectDuration(int minutes) {
    if (phase != MonkSessionPhase.idle) return;
    selectedMinutes = minutes;
    notifyListeners();
  }

  void startSession() {
    HapticFeedback.mediumImpact();
    _totalDuration = Duration(minutes: selectedMinutes);
    remaining = _totalDuration;
    breathCycles = 0;
    phase = MonkSessionPhase.active;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (phase != MonkSessionPhase.active) return;

    remaining = remaining - const Duration(seconds: 1);

    if (remaining.inSeconds <= 0) {
      remaining = Duration.zero;
      _completeSession(interrupted: false);
      return;
    }

    notifyListeners();
  }

  /// Called by [BreathingCircle] each time it completes a full
  /// inhale-hold-exhale cycle.
  void registerBreathCycle() {
    if (phase != MonkSessionPhase.active) return;
    breathCycles++;
  }

  Future<void> _completeSession({required bool interrupted}) async {
    _timer?.cancel();
    _timer = null;

    final elapsedMinutes = interrupted
        ? ((_totalDuration.inSeconds - remaining.inSeconds) / 60).round()
        : selectedMinutes;

    final session = MonkSession(
      id: 'session-${DateTime.now().microsecondsSinceEpoch}',
      userId: _userId ?? 'unknown',
      durationMinutes: interrupted ? elapsedMinutes : selectedMinutes,
      completedAt: DateTime.now(),
      breathCycles: breathCycles,
      wasInterrupted: interrupted,
    );

    lastCompletedSession = session;
    phase = MonkSessionPhase.completed;
    HapticFeedback.heavyImpact();
    notifyListeners();

    await _persistSession(session);
  }

  Future<void> _persistSession(MonkSession session) async {
    if (_saving) return;
    _saving = true;
    try {
      await _gateway.saveSession(_userId ?? 'unknown', session);
      history = [session, ...history];
      stats = MonkModeStats.fromHistory(history);
      onSessionComplete?.call(session);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Called when the user forces their way out of an active session
  /// (confirms through the exit-friction overlay). Records the session
  /// as interrupted and feeds whatever progress was made into history.
  Future<void> abandonSession() async {
    if (phase != MonkSessionPhase.active) return;
    await _completeSession(interrupted: true);
  }

  /// Resets back to the setup screen, ready for another session.
  void reset() {
    _timer?.cancel();
    _timer = null;
    phase = MonkSessionPhase.idle;
    remaining = Duration.zero;
    breathCycles = 0;
    lastCompletedSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
