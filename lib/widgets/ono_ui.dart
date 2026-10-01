import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Shared building blocks for the redesigned Today / Plan / Playbook
/// surfaces. Flat, bordered surfaces; one accent; lane color only as a
/// small signal (dot, bar), never as a fill.

class OnoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;
  final Color? color;
  final bool highlight;

  const OnoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent,
    this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlight
        ? AppColors.accent.withValues(alpha: 0.55)
        : AppColors.divider;
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.radius),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: accent == null
            ? content
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3, color: accent),
                    Expanded(child: content),
                  ],
                ),
              ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(0, 28, 0, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), style: AppText.eyebrow())),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppText.small(color: AppColors.accent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class LaneDot extends StatelessWidget {
  final String lane;
  final double size;

  const LaneDot(this.lane, {super.key, this.size = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.lane(lane),
          shape: BoxShape.circle,
        ),
      );
}

class Tag extends StatelessWidget {
  final String label;
  final Color? color;

  const Tag(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppText.small(color: c)
              .copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// A row with a round check, title and optional subtitle.
class CheckRow extends StatelessWidget {
  final bool checked;
  final String title;
  final String? subtitle;
  final String? lane;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsGeometry padding;

  const CheckRow({
    super.key,
    required this.checked,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.lane,
    this.padding = const EdgeInsets.symmetric(vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!checked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: subtitle == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: checked ? AppColors.accent : AppColors.grey,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: AppColors.ink)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(
                      color: checked ? AppColors.grey : AppColors.white,
                    ).copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.grey,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.small()),
                  ],
                ],
              ),
            ),
            if (lane != null) ...[
              const SizedBox(width: 10),
              LaneDot(lane!, size: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin progress ring drawn with CustomPaint.
class ScoreRing extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color color;
  final Widget? center;

  const ScoreRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.stroke = 5,
    this.color = AppColors.accent,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => CustomPaint(
          painter: _RingPainter(value, stroke, color),
          child: Center(child: child),
        ),
        child: center,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color color;

  _RingPainter(this.progress, this.stroke, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = AppColors.cardLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    if (progress <= 0) return;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Thin horizontal progress bar.
class ThinBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const ThinBar(
      {super.key,
      required this.value,
      this.color = AppColors.accent,
      this.height = 4});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.cardLight,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Standard page: large title, optional subtitle, back button when pushed,
/// slivers body, bottom padding that clears the floating nav bar.
class OnoPage extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> children;
  final bool showBack;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;

  const OnoPage({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.subtitle,
    this.showBack = false,
    this.actions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(
          AppSpace.gutter, 8, AppSpace.gutter, bottom + 120),
      children: [
        if (showBack || actions != null)
          Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                ),
              const Spacer(),
              ...?actions,
            ],
          ),
        SizedBox(height: showBack ? 16 : 12),
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(),
              style: AppText.eyebrow(color: AppColors.accent)),
          const SizedBox(height: 8),
        ],
        Text(title, style: AppText.display()),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AppText.body(color: AppColors.grey)),
        ],
        ...children,
      ],
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: onRefresh == null
            ? list
            : RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.card,
                onRefresh: onRefresh!,
                child: list,
              ),
      ),
    );
  }
}

/// Icon in a soft rounded square.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconTile(this.icon,
      {super.key, this.color = AppColors.accent, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

/// Label/value line used in definition-style lists.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const KeyValueRow(this.label, this.value,
      {super.key, this.labelWidth = 104});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(label,
                  style: AppText.small(color: AppColors.grey)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(child: Text(value, style: AppText.body())),
          ],
        ),
      );
}

Future<void> copyText(BuildContext context, String text,
    {String message = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.lightImpact();
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<void> openLink(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String weekdayName(int weekday) => const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][weekday - 1];

String monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];
