import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final month = system.programMonth;
    final now = DateTime.now();
    final current = currentBook(month);

    return OnoPage(
      showBack: true,
      eyebrow: 'Playbook',
      title: 'Library',
      subtitle:
          'One craft book a month at lunch, one novel on weekends, a podcast every drive, a source every morning.',
      children: [
        const SizedBox(height: 20),
        OnoCard(
          highlight: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('READING NOW · MONTH $month',
                  style: AppText.eyebrow(color: AppColors.accent)),
              const SizedBox(height: 12),
              Text(current.title, style: AppText.title()),
              const SizedBox(height: 2),
              Text(current.author, style: AppText.body()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Tag(current.chapters, color: AppColors.accent),
                  const Tag('20 min at lunch'),
                  const Tag('+ 5 min Feynman'),
                ],
              ),
              const SizedBox(height: 12),
              Text(current.why, style: AppText.small()),
            ],
          ),
        ),
        const SectionHeader('Craft — the 6-month sequence'),
        OnoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < bookSchedule.length; i++) ...[
                _BookRow(
                    book: bookSchedule[i],
                    isCurrent: bookSchedule[i].month == month,
                    isPast: (bookSchedule[i].month ?? 0) < month,
                    done: system.isDone('book:${bookSchedule[i].title}'),
                    onToggle: () =>
                        system.toggleDone('book:${bookSchedule[i].title}')),
                if (i < bookSchedule.length - 1) const Divider(),
              ],
            ],
          ),
        ),
        const SectionHeader('Fiction — weekends'),
        OnoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < fictionSchedule.length; i++) ...[
                _BookRow(
                    book: fictionSchedule[i],
                    isCurrent: fictionSchedule[i].month == month,
                    isPast: (fictionSchedule[i].month ?? 0) < month,
                    done: system.isDone('book:${fictionSchedule[i].title}'),
                    onToggle: () => system
                        .toggleDone('book:${fictionSchedule[i].title}')),
                if (i < fictionSchedule.length - 1) const Divider(),
              ],
            ],
          ),
        ),
        const SectionHeader('Films — with a reason'),
        for (final f in filmList)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => system.toggleDone('film:${f.title}'),
                    child: Icon(
                      system.isDone('film:${f.title}')
                          ? Icons.check_circle_rounded
                          : Icons.movie_outlined,
                      color: system.isDone('film:${f.title}')
                          ? AppColors.accent
                          : AppColors.grey,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                                child: Text(f.title,
                                    style: AppText.heading())),
                            const SizedBox(width: 6),
                            Text('${f.year}', style: AppText.small()),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(f.why, style: AppText.small()),
                        const SizedBox(height: 8),
                        Tag(f.when, color: AppColors.steel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SectionHeader('Podcasts — by day'),
        OnoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final p in podcastRotation)
                _RotationRow(
                    day: p.weekday,
                    title: p.title,
                    detail: p.detail,
                    isToday: p.weekday == now.weekday),
            ],
          ),
        ),
        const SectionHeader('Domain scan — by day'),
        OnoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final s in domainScanRotation)
                _RotationRow(
                  day: s.weekday,
                  title: s.title,
                  detail: s.detail,
                  isToday: s.weekday == now.weekday,
                  url: s.url,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookRow extends StatelessWidget {
  final Book book;
  final bool isCurrent;
  final bool isPast;
  final bool done;
  final VoidCallback onToggle;

  const _BookRow({
    required this.book,
    required this.isCurrent,
    required this.isPast,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(book.slot,
                style: AppText.small(
                        color: isCurrent ? AppColors.accent : AppColors.grey)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    style: AppText.heading(
                        color: done ? AppColors.grey : AppColors.white)),
                Text('${book.author} · ${book.chapters}',
                    style: AppText.small()),
                const SizedBox(height: 4),
                Text(book.why,
                    style: AppText.small(color: AppColors.greyLight)),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggle,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              done ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: done ? AppColors.accent : AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

class _RotationRow extends StatelessWidget {
  final int day;
  final String title;
  final String detail;
  final bool isToday;
  final String? url;

  const _RotationRow({
    required this.day,
    required this.title,
    required this.detail,
    required this.isToday,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: url == null ? null : () => openLink(url!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(weekdayName(day).substring(0, 3).toUpperCase(),
                  style: AppText.eyebrow(
                      color: isToday ? AppColors.accent : AppColors.grey)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.body(
                              color: isToday
                                  ? AppColors.white
                                  : AppColors.greyLight)
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(detail, style: AppText.small()),
                ],
              ),
            ),
            if (url != null)
              const Icon(Icons.north_east_rounded,
                  size: 16, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
