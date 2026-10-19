import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Shared building blocks. Flat hairline surfaces, one accent, lane color
/// only as a small signal. Every screen uses these so the app reads as one
/// product.

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
    final borderColor =
        highlight ? AppColors.accent.withValues(alpha: 0.6) : AppColors.divider;
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
    this.padding = const EdgeInsets.fromLTRB(0, 30, 0, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: AppText.serif(size: 24))),
          if (action != null)
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                // A bigger target than the word: easier to hit.
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 0, 3),
                  child: Text(action!,
                      style: AppText.small(color: AppColors.accent)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppText.small(color: c)
              .copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// A row with a round check, title and optional subtitle. Checking springs
/// the mark and gives a haptic tap.
class CheckRow extends StatelessWidget {
  final bool checked;
  final String title;
  final String? subtitle;
  final String? lane;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onOpen;
  final EdgeInsetsGeometry padding;

  const CheckRow({
    super.key,
    required this.checked,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.lane,
    this.onOpen,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final mark = lane == null ? AppColors.accent : AppColors.lane(lane!);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      // Screen readers hear the item and whether it is done.
      checked: checked,
      button: true,
      child: InkWell(
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
              TweenAnimationBuilder<double>(
                key: ValueKey(checked),
                tween: Tween(begin: checked && !still ? 0.6 : 1, end: 1),
                duration: Duration(milliseconds: still ? 0 : 380),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked ? mark : Colors.transparent,
                    border: Border.all(
                      color: checked ? mark : AppColors.faint,
                      width: 1.6,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.ink)
                      : null,
                ),
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
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppText.small()),
                    ],
                  ],
                ),
              ),
              if (onOpen != null)
                IconButton(
                  onPressed: onOpen,
                  tooltip: 'Open $title',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ring progress drawn with CustomPaint.
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
    this.stroke = 8,
    this.color = AppColors.accent,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // The centre usually says the number; without one, say the share.
    return Semantics(
      value: center == null
          ? '${(progress.clamp(0, 1) * 100).round()} percent'
          : null,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0, 1)),
          duration: Duration(milliseconds: still ? 0 : 600),
          curve: Curves.easeOutCubic,
          builder: (_, value, child) => CustomPaint(
            painter: _RingPainter(value, stroke, color),
            child: Center(child: child),
          ),
          child: center,
        ),
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
    final r = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
        r,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = AppColors.cardLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (progress <= 0) return;
    canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Horizontal progress bar.
class ThinBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const ThinBar(
      {super.key,
      required this.value,
      this.color = AppColors.accent,
      this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: AppColors.cardLight,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

/// N segments, the first [filled] coloured — reads better than a bar for
/// small counts (Daily 10, 3 gym sessions, 4 Pennebaker sessions).
class TickSegments extends StatelessWidget {
  final int total;
  final int filled;
  final Color color;
  final double height;
  final List<Color>? colors;

  const TickSegments({
    super.key,
    required this.total,
    required this.filled,
    this.color = AppColors.accent,
    this.height = 6,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final done = colors == null
        ? filled
        : [for (var i = 0; i < total && i < colors!.length; i++) colors![i]]
            .where((c) => c != AppColors.cardLight)
            .length;
    return Semantics(
      label: '$done of $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: still ? 0 : 200 + i * 30),
                height: height,
                decoration: BoxDecoration(
                  color: i < filled
                      ? (colors != null ? colors![i] : color)
                      : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

/// Full-width primary action: cognac fill, ink text.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const PrimaryButton(this.label,
      {super.key, this.onPressed, this.icon, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onPressed!();
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.cardLight,
          disabledForegroundColor: AppColors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.ink))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19),
                    const SizedBox(width: 8),
                  ],
                  // Large text sizes: the label shrinks to fit, never
                  // overflows the button.
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.heading(color: AppColors.ink)
                            .copyWith(fontSize: 16)),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary action: hairline, ivory text.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GhostButton(this.label, {super.key, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small(color: AppColors.white)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented sub-navigation for long pages.
class Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const Segmented(
      {super.key,
      required this.labels,
      required this.index,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        i == index ? AppColors.cardLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small(
                      color: i == index ? AppColors.white : AppColors.grey,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Number + label tile.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;
  final Color color;

  const StatTile(this.value, this.label,
      {super.key, this.unit, this.color = AppColors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.number(size: 24, color: color)),
            ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(unit!, style: AppText.small()),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(label, maxLines: 2, style: AppText.small().copyWith(fontSize: 12)),
      ],
    );
  }
}

/// Honest empty state.
class EmptyNote extends StatelessWidget {
  final String text;
  final IconData icon;

  const EmptyNote(this.text,
      {super.key, this.icon = Icons.hourglass_empty_rounded});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.faint),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppText.small())),
          ],
        ),
      );
}

class OnoBackButton extends StatelessWidget {
  final IconData icon;
  const OnoBackButton({super.key, this.icon = Icons.arrow_back_rounded});

  @override
  Widget build(BuildContext context) => IconButton(
        // maybePop, so a page guarding unsaved writing (UnsavedGuard) can
        // ask first.
        onPressed: () => context.canPop()
            ? Navigator.of(context).maybePop()
            : context.go('/home'),
        tooltip: icon == Icons.close_rounded ? 'Close' : 'Back',
        icon: Icon(icon, color: AppColors.white),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.divider),
        ),
      );
}

/// Standard page: optional back button, eyebrow, serif title, subtitle,
/// then children; bottom padding clears the nav bar.
class OnoPage extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> children;
  final bool showBack;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;
  final Widget? bottomBar;

  const OnoPage({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.subtitle,
    this.showBack = false,
    this.actions,
    this.onRefresh,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(AppSpace.gutter, 8, AppSpace.gutter,
          bottomBar != null ? 24 : bottom + 110),
      children: [
        if (showBack || actions != null)
          Row(
            children: [
              if (showBack) const OnoBackButton(),
              const Spacer(),
              ...?actions,
            ],
          ),
        SizedBox(height: showBack || actions != null ? 14 : 10),
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(),
              style: AppText.eyebrow(color: AppColors.accent)),
          const SizedBox(height: 6),
        ],
        Text(title, style: showBack ? AppText.title() : AppText.display()),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AppText.body(color: AppColors.grey)),
        ],
        ...children,
      ],
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: bottomBar == null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: bottomBar,
            ),
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
          color: color.withValues(alpha: 0.13),
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

  const KeyValueRow(this.label, this.value, {super.key, this.labelWidth = 104});

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

/// Single-line list row with icon, title, subtitle and chevron.
class LinkRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  /// Where it leads, so a group of links can tell which were used lately.
  final String? route;

  const LinkRow({
    super.key,
    this.route,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = AppColors.grey,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              IconTile(icon, color: color, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.heading().copyWith(fontSize: 15.5)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small()),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(trailing!,
                    style: AppText.small(color: AppColors.greyLight)
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
            ],
          ),
        ),
      );
}

Future<void> copyText(BuildContext context, String text,
    {String message = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.lightImpact();
  if (context.mounted) toast(context, message);
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> openLink(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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

String shortDate(DateTime d) =>
    '${d.day} ${monthName(d.month).substring(0, 3)}';

/// Asks before leaving a page that has writing on it: one stray swipe or
/// tap shouldn't lose what someone wrote in a hard moment. Empty pages
/// leave freely (and keep the iOS swipe-back).
class UnsavedGuard extends StatefulWidget {
  final List<TextEditingController> fields;
  final Widget child;

  /// For pages edited in place (opened with saved text): only changes
  /// since opening, or since [markSaved], count as unsaved.
  final bool changesOnly;

  /// Bump after saving a page that stays open: what's there now counts as
  /// saved, and later edits are guarded again.
  final int saves;
  const UnsavedGuard(
      {super.key,
      required this.fields,
      required this.child,
      this.changesOnly = false,
      this.saves = 0});

  @override
  State<UnsavedGuard> createState() => _UnsavedGuardState();
}

class _UnsavedGuardState extends State<UnsavedGuard> {
  bool _dirty = false;
  List<String> _baseline = const [];

  /// Set once the page saved, so its own pop goes straight through.
  static final _released = Expando<bool>();

  /// Call before popping a page after saving it.
  static void release(BuildContext context) {
    final s = context.findAncestorStateOfType<_UnsavedGuardState>();
    if (s != null) {
      _released[s] = true;
      if (s.mounted) s.setState(() => s._dirty = false);
    }
  }

  void _check() {
    final fields = widget.fields;
    final d = _released[this] != true &&
        (widget.changesOnly
            ? [for (var i = 0; i < fields.length; i++) i]
                .any((i) => fields[i].text.trim() != _baseline[i].trim())
            : fields.any((c) => c.text.trim().isNotEmpty));
    if (d != _dirty) setState(() => _dirty = d);
  }

  @override
  void initState() {
    super.initState();
    _baseline = [for (final c in widget.fields) c.text];
    for (final c in widget.fields) {
      c.addListener(_check);
    }
  }

  @override
  void didUpdateWidget(UnsavedGuard old) {
    super.didUpdateWidget(old);
    if (old.saves != widget.saves) {
      _baseline = [for (final c in widget.fields) c.text];
      _dirty = false;
    }
  }

  @override
  void dispose() {
    for (final c in widget.fields) {
      c.removeListener(_check);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final leave = await showDialog<bool>(
            context: context,
            builder: (d) => AlertDialog(
              title: const Text('Leave without saving?'),
              content: const Text('What you wrote here will be lost.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(d, false),
                    child: const Text('Keep writing')),
                TextButton(
                    onPressed: () => Navigator.pop(d, true),
                    child: const Text('Discard')),
              ],
            ),
          );
          if (leave == true && context.mounted) {
            setState(() => _dirty = false);
            _released[this] = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.of(context).pop();
            });
          }
        },
        child: widget.child,
      );
}

/// Lets a page pop after saving even though its fields have text.
void releaseUnsavedGuard(BuildContext context) =>
    _UnsavedGuardState.release(context);
