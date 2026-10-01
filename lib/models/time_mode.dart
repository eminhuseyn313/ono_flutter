import 'package:flutter/material.dart';

/// The four time-of-day modes.
enum TimeOfDayMode { dawn, day, evening, night }

/// Immutable configuration for a single time-of-day mode.
class TimeModeConfig {
  final TimeOfDayMode mode;
  final String displayName;
  final String emoji;
  final List<Color> gradient;
  final Color accentColor;
  final List<String> quotePool;
  final int hourStart; // inclusive
  final int hourEnd; // exclusive

  const TimeModeConfig({
    required this.mode,
    required this.displayName,
    required this.emoji,
    required this.gradient,
    required this.accentColor,
    required this.quotePool,
    required this.hourStart,
    required this.hourEnd,
  });

  /// Whether [hour] (0-23) falls within this mode's range.
  bool containsHour(int hour) {
    if (hourStart < hourEnd) {
      return hour >= hourStart && hour < hourEnd;
    }
    // Wraps midnight (night: 21-4).
    return hour >= hourStart || hour < hourEnd;
  }

  /// Human-readable hour range string.
  String get hourRangeLabel {
    String _fmt(int h) {
      if (h == 0 || h == 24) return '12 AM';
      if (h == 12) return '12 PM';
      if (h < 12) return '$h AM';
      return '${h - 12} PM';
    }

    return '${_fmt(hourStart)} – ${_fmt(hourEnd)}';
  }

  TimeModeConfig copyWith({
    TimeOfDayMode? mode,
    String? displayName,
    String? emoji,
    List<Color>? gradient,
    Color? accentColor,
    List<String>? quotePool,
    int? hourStart,
    int? hourEnd,
  }) {
    return TimeModeConfig(
      mode: mode ?? this.mode,
      displayName: displayName ?? this.displayName,
      emoji: emoji ?? this.emoji,
      gradient: gradient ?? this.gradient,
      accentColor: accentColor ?? this.accentColor,
      quotePool: quotePool ?? this.quotePool,
      hourStart: hourStart ?? this.hourStart,
      hourEnd: hourEnd ?? this.hourEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'displayName': displayName,
      'emoji': emoji,
      'gradient': gradient.map((c) => c.value).toList(),
      'accentColor': accentColor.value,
      'quotePool': quotePool,
      'hourStart': hourStart,
      'hourEnd': hourEnd,
    };
  }

  factory TimeModeConfig.fromJson(Map<String, dynamic> json) {
    return TimeModeConfig(
      mode: TimeOfDayMode.values.byName(json['mode'] as String),
      displayName: json['displayName'] as String,
      emoji: json['emoji'] as String,
      gradient: (json['gradient'] as List)
          .map((v) => Color(v as int))
          .toList(),
      accentColor: Color(json['accentColor'] as int),
      quotePool: List<String>.from(json['quotePool'] as List),
      hourStart: json['hourStart'] as int,
      hourEnd: json['hourEnd'] as int,
    );
  }

  // ---------------------------------------------------------------------------
  // Static preset configs
  // ---------------------------------------------------------------------------

  static const List<TimeModeConfig> allModes = [
    dawnConfig,
    dayConfig,
    eveningConfig,
    nightConfig,
  ];

  /// Returns the config whose hour range contains [hour].
  static TimeModeConfig configForHour(int hour) {
    return allModes.firstWhere((c) => c.containsHour(hour));
  }

  // -- Dawn (4 AM – 7 AM) ----------------------------------------------------

  static const dawnConfig = TimeModeConfig(
    mode: TimeOfDayMode.dawn,
    displayName: 'Dawn',
    emoji: '🌅',
    gradient: [
      Color(0xFF1A0533), // deep violet
      Color(0xFF4A2F18), // purple dark
      Color(0xFFD97706), // amber
      Color(0xFFE8C46A), // warm gold
    ],
    accentColor: Color(0xFFE8C46A),
    hourStart: 4,
    hourEnd: 7,
    quotePool: [
      'The early morning has gold in its mouth.',
      'Every sunrise is an invitation to brighten someone\'s day.',
      'Wake up with determination, go to bed with satisfaction.',
      'The secret of getting ahead is getting started.',
      'Morning is the start of every great change.',
      'Discipline is the bridge between goals and accomplishment.',
      'Your future is created by what you do today, not tomorrow.',
      'Rise before the world and own the silence.',
      'Small disciplines repeated with consistency lead to great achievements.',
      'The dawn is yours. Seize it before the noise begins.',
    ],
  );

  // -- Day (7 AM – 6 PM) -----------------------------------------------------

  static const dayConfig = TimeModeConfig(
    mode: TimeOfDayMode.day,
    displayName: 'Day',
    emoji: '☀️',
    gradient: [
      Color(0xFF0C0D0F), // background
      Color(0xFF15171B), // card
      Color(0xFF1E2126), // card light
    ],
    accentColor: Color(0xFFC8894A), // purple accent (standard)
    hourStart: 7,
    hourEnd: 18,
    quotePool: [
      'Focus on being productive instead of busy.',
      'Do the hard things first. Everything else will feel easy.',
      'Action is the foundational key to all success.',
      'Don\'t watch the clock; do what it does — keep going.',
      'Productivity is never an accident. It is the result of commitment.',
      'The way to get started is to quit talking and begin doing.',
      'Success usually comes to those who are too busy to be looking for it.',
      'You don\'t need more time. You need more focus.',
      'Effort only fully releases its reward after a person refuses to quit.',
      'One percent better every day compounds into greatness.',
    ],
  );

  // -- Evening (6 PM – 9 PM) -------------------------------------------------

  static const eveningConfig = TimeModeConfig(
    mode: TimeOfDayMode.evening,
    displayName: 'Evening',
    emoji: '🌇',
    gradient: [
      Color(0xFF0F172A), // dark blue-grey
      Color(0xFF581C87), // deep purple
      Color(0xFFB45309), // warm orange-brown
      Color(0xFFE0605A), // sunset red
    ],
    accentColor: Color(0xFFE2B354), // warm amber
    hourStart: 18,
    hourEnd: 21,
    quotePool: [
      'Reflect on your day — progress is often invisible from up close.',
      'Evening is a time to be grateful for everything the day offered.',
      'Prepare tonight what you want to become tomorrow.',
      'Rest is not idleness; it is the soil in which growth takes root.',
      'Review today. Plan tomorrow. Release what you cannot control.',
      'Celebrate small wins — they are the evidence of momentum.',
      'The evening rewards those who gave the day their honest effort.',
      'Let go of perfection. Done is better than flawless.',
      'Wind down with intention, not just distraction.',
      'Tomorrow\'s clarity begins with tonight\'s reflection.',
    ],
  );

  // -- Night (9 PM – 4 AM) ---------------------------------------------------

  static const nightConfig = TimeModeConfig(
    mode: TimeOfDayMode.night,
    displayName: 'Night',
    emoji: '🌙',
    gradient: [
      Color(0xFF030712), // near black
      Color(0xFF0C0D0F), // background
      Color(0xFF1E1B4B), // indigo midnight
    ],
    accentColor: Color(0xFFE8C46A), // amber
    hourStart: 21,
    hourEnd: 4,
    quotePool: [
      'Sleep is the best meditation.',
      'The night is longer than the day for those who dream.',
      'Let the stillness of night restore what the day has worn.',
      'Your body keeps the score. Give it rest.',
      'Great things happen when you let your mind be still.',
      'Tonight, give yourself permission to fully recharge.',
      'The stars remind us: there is light even in darkness.',
      'Sleep is an investment in the energy you need tomorrow.',
      'Release the day. It has already given you everything it can.',
      'Quiet the mind and the soul will speak.',
    ],
  );
}
