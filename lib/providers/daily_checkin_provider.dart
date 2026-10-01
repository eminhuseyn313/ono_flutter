import 'package:flutter/foundation.dart';

import '../gateways/daily_checkin_gateway.dart';
import '../models/daily_checkin.dart';

class DailyCheckinProvider extends ChangeNotifier {
  final DailyCheckinGateway _gateway;

  DailyCheckinProvider({required DailyCheckinGateway gateway})
      : _gateway = gateway;

  DailyCheckin? _todayCheckin;
  CheckinHistory? _history;
  bool _isLoading = false;
  String? _error;

  // Working state for building the checkin
  CheckinMood? _selectedMood;
  double _energyLevel = 0.5;
  List<String> _gratitudes = [];
  String _intention = '';
  FocusArea? _primaryFocus;
  String _eveningReflection = '';
  double _dayRating = 3.0;
  CheckinMood? _eveningMood;

  DailyCheckin? get todayCheckin => _todayCheckin;
  CheckinHistory? get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CheckinMood? get selectedMood => _selectedMood;
  double get energyLevel => _energyLevel;
  List<String> get gratitudes => _gratitudes;
  String get intention => _intention;
  FocusArea? get primaryFocus => _primaryFocus;
  String get eveningReflection => _eveningReflection;
  double get dayRating => _dayRating;
  CheckinMood? get eveningMood => _eveningMood;

  bool get isMorningComplete => _todayCheckin?.morningComplete ?? false;
  bool get isEveningComplete => _todayCheckin?.eveningComplete ?? false;

  CheckinTime get suggestedTime {
    final hour = DateTime.now().hour;
    if (hour < 14 && !isMorningComplete) return CheckinTime.morning;
    return CheckinTime.evening;
  }

  Future<void> loadToday() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayCheckin = await _gateway.loadTodayCheckin();
      if (_todayCheckin != null) {
        _selectedMood = _todayCheckin!.morningMood;
        _energyLevel = _todayCheckin!.energyLevel ?? 0.5;
        _gratitudes = List.from(_todayCheckin!.gratitudes);
        _intention = _todayCheckin!.intention ?? '';
        _primaryFocus = _todayCheckin!.primaryFocus;
        _eveningReflection = _todayCheckin!.eveningReflection ?? '';
        _dayRating = _todayCheckin!.dayRating ?? 3.0;
        _eveningMood = _todayCheckin!.eveningMood;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    try {
      _history = await _gateway.loadCheckinHistory();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setMood(CheckinMood mood) {
    _selectedMood = mood;
    notifyListeners();
  }

  void setEnergy(double energy) {
    _energyLevel = energy;
    notifyListeners();
  }

  void setFocus(FocusArea focus) {
    _primaryFocus = focus;
    notifyListeners();
  }

  void addGratitude(String gratitude) {
    if (gratitude.trim().isEmpty) return;
    _gratitudes = [..._gratitudes, gratitude.trim()];
    notifyListeners();
  }

  void removeGratitude(int index) {
    if (index < 0 || index >= _gratitudes.length) return;
    _gratitudes = List.from(_gratitudes)..removeAt(index);
    notifyListeners();
  }

  void setIntention(String intention) {
    _intention = intention;
    notifyListeners();
  }

  void setPrimaryFocus(FocusArea focus) {
    _primaryFocus = focus;
    notifyListeners();
  }

  Future<void> completeMorning() async {
    _isLoading = true;
    notifyListeners();

    try {
      final checkin = DailyCheckin(
        id: _todayCheckin?.id ?? 'checkin_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        morningMood: _selectedMood,
        energyLevel: _energyLevel,
        gratitudes: _gratitudes,
        intention: _intention,
        primaryFocus: _primaryFocus,
      );
      _todayCheckin = await _gateway.saveMorningCheckin(checkin);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEveningReflection(String reflection) {
    _eveningReflection = reflection;
    notifyListeners();
  }

  void setDayRating(double rating) {
    _dayRating = rating;
    notifyListeners();
  }

  void setEveningMood(CheckinMood mood) {
    _eveningMood = mood;
    notifyListeners();
  }

  Future<void> completeEvening() async {
    _isLoading = true;
    notifyListeners();

    try {
      final checkin = (_todayCheckin ?? DailyCheckin(
        id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
      )).copyWith(
        eveningReflection: _eveningReflection,
        dayRating: _dayRating,
        eveningMood: _eveningMood,
      );
      _todayCheckin = await _gateway.saveEveningCheckin(checkin);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
