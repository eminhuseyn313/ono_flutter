import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/personal_system.dart';
import '../data/emin_system.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════
// Day Dial — the day 06:00 → 22:30 as a 270° gauge. Outer arcs are the
// schedule blocks in lane colour (past blocks solid, future faint), the
// cognac needle is "now", the inner ticks are the Daily 10.
// ═══════════════════════════════════════════════════════════════════════

class DayDial extends StatelessWidget {
  final DateTime now;
  final List<({String lane, bool done})> ticks;
  final Widget center;
  final double size;

  /// Schedule blocks drawn as lane arcs; empty for a plan without one.
  final List<ScheduleBlock> schedule;

  const DayDial({
    super.key,
    required this.now,
    required this.ticks,
    required this.center,
    this.size = 280,
    this.schedule = dailySchedule,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, child) => CustomPaint(
          painter: _DayDialPainter(
              now: now, ticks: ticks, reveal: t, schedule: schedule),
          child: child,
        ),
        child: Center(
          child: SizedBox(width: size * 0.56, child: center),
        ),
      ),
    );
  }
}

class _DayDialPainter extends CustomPainter {
  final DateTime now;
  final List<({String lane, bool done})> ticks;
  final double reveal;
  final List<ScheduleBlock> schedule;

  _DayDialPainter(
      {required this.now,
      required this.ticks,
      required this.reveal,
      required this.schedule});

  static const _start = 135 * math.pi / 180; // bottom-left
  static const _sweep = 270 * math.pi / 180;
  static const _dayStart = 6 * 60;
  static const _dayEnd = 22 * 60 + 30;

  double _angleFor(int minuteOfDay) {
    final f = ((minuteOfDay - _dayStart) / (_dayEnd - _dayStart)).clamp(0, 1);
    return _start + _sweep * f;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outerR = size.width / 2 - 10;
    final innerR = outerR - 26;
    final nowMin = now.hour * 60 + now.minute;

    // Track.
    final track = Paint()
      ..color = AppColors.cardLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: outerR), _start, _sweep,
        false, track);

    // Schedule blocks.
    for (var i = 0; i < schedule.length; i++) {
      final b = schedule[i];
      final endMin =
          i + 1 < schedule.length ? schedule[i + 1].minuteOfDay : _dayEnd;
      if (b.minuteOfDay >= _dayEnd) continue;
      final a0 = _angleFor(b.minuteOfDay);
      final a1 = _angleFor(endMin);
      const gap = 0.012;
      final sweep = (a1 - a0 - gap) * reveal;
      if (sweep <= 0) continue;
      final past = endMin <= nowMin;
      final current = b.minuteOfDay <= nowMin && nowMin < endMin;
      final col = AppColors.lane(b.lane)
          .withValues(alpha: current ? 1 : (past ? 0.75 : 0.28));
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: outerR),
          a0,
          sweep,
          false,
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = current ? 14 : 12
            ..strokeCap = StrokeCap.butt);
    }

    // Hour labels at 06, 12, 18, 22:30.
    for (final m in [6 * 60, 12 * 60, 18 * 60, _dayEnd]) {
      final a = _angleFor(m);
      final p = c + Offset(math.cos(a), math.sin(a)) * (outerR + 0.5);
      canvas.drawCircle(p, 2, Paint()..color = AppColors.background);
    }

    // Daily 10 ticks on the inner ring.
    if (ticks.isNotEmpty) {
      final per = _sweep / ticks.length;
      for (var i = 0; i < ticks.length; i++) {
        final t = ticks[i];
        final a0 = _start + per * i + 0.04;
        canvas.drawArc(
            Rect.fromCircle(center: c, radius: innerR),
            a0,
            (per - 0.08) * reveal,
            false,
            Paint()
              ..color = t.done ? AppColors.lane(t.lane) : AppColors.cardLight
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeCap = StrokeCap.round);
      }
    }

    // Now needle.
    if (nowMin >= _dayStart && nowMin <= _dayEnd) {
      final a = _angleFor(nowMin);
      final dir = Offset(math.cos(a), math.sin(a));
      final p1 = c + dir * (outerR - 13);
      final p2 = c + dir * (outerR + 13);
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = AppColors.accent
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(p2, 4.5, Paint()..color = AppColors.accent);
    }
  }

  @override
  bool shouldRepaint(_DayDialPainter old) =>
      old.now != now || old.ticks != ticks || old.reveal != reveal;
}

// ═══════════════════════════════════════════════════════════════════════
// Spine — the 18 months as columns on a navy band: phases above, role
// steps, milestone dots, and the Daily 10 heat map (30 cells per month).
// ═══════════════════════════════════════════════════════════════════════

class SpineMonth {
  final int month;
  final int milestonesDone;
  final int milestonesTotal;

  /// 30 Daily 10 scores for the month (null = future / outside program).
  final List<int?> scores;

  const SpineMonth(
      {required this.month,
      required this.milestonesDone,
      required this.milestonesTotal,
      required this.scores});
}

class Spine extends StatelessWidget {
  final List<SpineMonth> months;
  final int currentMonth;
  final ValueChanged<int> onMonthTap;

  /// Role steps along the top: [label, month].
  final List<List<String>> steps;

  /// The phase the program is in now (phases scale with its length).
  final String? currentPhaseId;

  const Spine({
    super.key,
    required this.months,
    required this.currentMonth,
    required this.onMonthTap,
    this.steps = pathSteps,
    this.currentPhaseId,
  });

  static const _baseColW = 62.0;

  /// Columns widen for a short program so the spine still fills the card.
  double get colW => math.max(_baseColW, 330 / math.max(1, months.length));

  bool _isCurrent(Phase p) => currentPhaseId == null
      ? p.contains(currentMonth)
      : p.id == currentPhaseId;

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController(
        initialScrollOffset: math.max(0, (currentMonth - 2) * colW).toDouble());
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppSpace.radius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase bands
            Row(
              children: [
                for (final p in phases)
                  Container(
                    width: colW *
                        months.length *
                        (p.toMonth - p.fromMonth + 1) /
                        programMonths,
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            // Too narrow to read: the bar alone shows it.
                            colW *
                                        months.length *
                                        (p.toMonth - p.fromMonth + 1) /
                                        programMonths <
                                    56
                                ? ''
                                : p.name.toUpperCase(),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppText.eyebrow(
                                color: _isCurrent(p)
                                    ? AppColors.accent
                                    : AppColors.grey)),
                        const SizedBox(height: 6),
                        Container(
                          height: 2,
                          color: _isCurrent(p)
                              ? AppColors.accent
                              : AppColors.navyLight,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Role steps
            SizedBox(
              height: 18,
              width: colW * months.length,
              child: Stack(
                children: [
                  for (final s in steps)
                    if (int.parse(s[1]) <= months.length)
                      Positioned(
                        left: colW * (int.parse(s[1]) - 1),
                        child: Text('▸ ${s[0]}',
                            style: AppText.small(color: AppColors.greyLight)
                                .copyWith(fontSize: 11)),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in months) _column(m),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _column(SpineMonth m) {
    final isNow = m.month == currentMonth;
    final isPast = m.month < currentMonth;
    return GestureDetector(
      onTap: () => onMonthTap(m.month),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: colW - 6,
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        decoration: BoxDecoration(
          color: isNow ? AppColors.navyLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isNow ? AppColors.accent : Colors.transparent, width: 1.4),
        ),
        child: Column(
          children: [
            Text('${m.month}',
                style: AppText.serif(
                    size: 22,
                    color: isNow
                        ? AppColors.accent
                        : isPast
                            ? AppColors.greyLight
                            : AppColors.grey)),
            const SizedBox(height: 6),
            // Milestone dots
            Wrap(
              spacing: 3,
              runSpacing: 3,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < m.milestonesTotal; i++)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < m.milestonesDone
                          ? AppColors.accent
                          : Colors.transparent,
                      border: Border.all(
                          color: i < m.milestonesDone
                              ? AppColors.accent
                              : AppColors.grey.withValues(alpha: 0.6)),
                    ),
                  ),
                if (m.milestonesTotal == 0)
                  Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navyLight))),
              ],
            ),
            const SizedBox(height: 10),
            // Heat cells 5 × 6
            SizedBox(
              width: 5 * 8.0 + 4 * 1.5,
              child: Wrap(
                spacing: 1.5,
                runSpacing: 1.5,
                children: [
                  for (final s in m.scores)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: heatColor(s, onNavy: true),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily 10 score → heat colour. null = future.
Color heatColor(int? score, {bool onNavy = false}) {
  if (score == null) {
    return onNavy
        ? AppColors.navyLight.withValues(alpha: 0.45)
        : AppColors.card;
  }
  if (score == 0) return onNavy ? const Color(0xFF2A3546) : AppColors.cardLight;
  if (score <= 4) return const Color(0xFF4A3524);
  if (score <= 6) return const Color(0xFF7A5230);
  if (score <= 8) return const Color(0xFFA86D35);
  return AppColors.accent;
}

/// Calendar heat map: columns are weeks (Mon→Sun rows).
class HeatGrid extends StatelessWidget {
  final DateTime from;
  final int weeks;
  final int? Function(DateTime day) scoreFor;

  const HeatGrid(
      {super.key,
      required this.from,
      required this.weeks,
      required this.scoreFor});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return LayoutBuilder(builder: (context, c) {
      final cell = ((c.maxWidth - (weeks - 1) * 3) / weeks).clamp(6.0, 16.0);
      return Row(
        children: [
          for (var w = 0; w < weeks; w++) ...[
            Column(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  Builder(builder: (_) {
                    final day = from.plusDays(w * 7 + d);
                    final future = day.isAfter(today);
                    return Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: heatColor(future ? null : scoreFor(day)),
                        borderRadius: BorderRadius.circular(3),
                        border: future
                            ? Border.all(color: AppColors.cardLight)
                            : null,
                      ),
                    );
                  }),
                  if (d < 6) const SizedBox(height: 3),
                ],
              ],
            ),
            if (w < weeks - 1) const SizedBox(width: 3),
          ],
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Line chart with an optional target band (e.g. weight 76–78 kg).
// ═══════════════════════════════════════════════════════════════════════

class TrendLine extends StatelessWidget {
  final List<({DateTime x, double y})> points;
  final double? bandLow;
  final double? bandHigh;
  final Color color;
  final double height;
  final String unit;

  const TrendLine({
    super.key,
    required this.points,
    this.bandLow,
    this.bandHigh,
    this.color = AppColors.body,
    this.height = 140,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(points, bandLow, bandHigh, color, unit),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<({DateTime x, double y})> points;
  final double? low;
  final double? high;
  final Color color;
  final String unit;

  _TrendPainter(this.points, this.low, this.high, this.color, this.unit);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final ys = [
      ...points.map((p) => p.y),
      if (low != null) low!,
      if (high != null) high!,
    ];
    var minY = ys.reduce(math.min) - 1;
    var maxY = ys.reduce(math.max) + 1;
    if (maxY - minY < 2) maxY = minY + 2;
    final x0 = points.first.x.millisecondsSinceEpoch.toDouble();
    var x1 = points.last.x.millisecondsSinceEpoch.toDouble();
    if (x1 == x0) x1 = x0 + 1;
    const leftPad = 34.0;
    final w = size.width - leftPad;
    final h = size.height - 18;

    Offset at(DateTime x, double y) => Offset(
        leftPad + w * ((x.millisecondsSinceEpoch - x0) / (x1 - x0)),
        h * (1 - (y - minY) / (maxY - minY)));

    // Grid labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final v in [minY, (minY + maxY) / 2, maxY]) {
      final y = h * (1 - (v - minY) / (maxY - minY));
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y),
          Paint()..color = AppColors.divider);
      tp.text = TextSpan(
          text: v.toStringAsFixed(0),
          style: AppText.small().copyWith(fontSize: 10.5));
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    if (low != null && high != null) {
      final yTop = h * (1 - (high! - minY) / (maxY - minY));
      final yBot = h * (1 - (low! - minY) / (maxY - minY));
      canvas.drawRect(Rect.fromLTRB(leftPad, yTop, size.width, yBot),
          Paint()..color = color.withValues(alpha: 0.12));
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = at(points[i].x, points[i].y);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    for (final p in points) {
      canvas.drawCircle(at(p.x, p.y), 3.5, Paint()..color = color);
    }
    final last = points.last;
    tp.text = TextSpan(
        text: '${last.y.toStringAsFixed(1)}$unit',
        style: AppText.small(color: AppColors.white)
            .copyWith(fontWeight: FontWeight.w700));
    tp.layout();
    final lp = at(last.x, last.y);
    tp.paint(
        canvas,
        Offset((lp.dx - tp.width).clamp(leftPad, size.width - tp.width),
            (lp.dy - tp.height - 8).clamp(0, h)));
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.points != points;
}

/// Seven bars (Mon→Sun) of Daily 10 scores; today outlined.
class WeekBars extends StatelessWidget {
  final List<int?> scores; // 7 values, null = future
  final int todayIndex;
  final double height;

  const WeekBars(
      {super.key,
      required this.scores,
      required this.todayIndex,
      this.height = 90});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0, end: ((scores[i] ?? 0) / 10).toDouble()),
                      duration: Duration(milliseconds: 400 + i * 60),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Container(
                        height: math.max(4, height * v),
                        decoration: BoxDecoration(
                          color: scores[i] == null
                              ? AppColors.cardLight
                              : heatColor(scores[i]),
                          borderRadius: BorderRadius.circular(5),
                          border: i == todayIndex
                              ? Border.all(color: AppColors.white, width: 1.2)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i],
                        style: AppText.small(
                                color: i == todayIndex
                                    ? AppColors.white
                                    : AppColors.grey)
                            .copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
