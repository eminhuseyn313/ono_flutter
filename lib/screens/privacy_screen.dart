import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Your data, in plain words: what ONO keeps, where it lives, what the
/// coach sees, and how to take it with you or delete it.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Widget _point(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.heading()),
                  const SizedBox(height: 2),
                  Text(body, style: AppText.small()),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _erase(BuildContext context, PersonalSystemProvider system) async {
    final typed = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Delete everything?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Every check, log, note, letter, goal and brief is deleted${system.syncsToCloud ? ' from this phone and from the cloud' : ' from this phone'}. This cannot be undone. Export a backup first if you might want it.',
                  style: AppText.small()),
              const SizedBox(height: 12),
              TextField(
                controller: typed,
                onChanged: (_) => setState(() {}),
                style: AppText.body(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Type DELETE'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep my data')),
            TextButton(
                onPressed: typed.text.trim() == 'DELETE'
                    ? () => Navigator.of(ctx).pop(true)
                    : null,
                child: const Text('Delete',
                    style: TextStyle(color: AppColors.danger))),
          ],
        ),
      ),
    );
    typed.dispose();
    if (ok != true || !context.mounted) return;
    try {
      await system.eraseEverything();
      if (context.mounted) {
        toast(context, 'Everything is deleted.');
        context.go('/start');
      }
    } catch (_) {
      if (context.mounted) {
        toast(context, 'Could not reach the cloud, so nothing was deleted. Try again online.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final d = system.dataSummary;
    return OnoPage(
      showBack: true,
      eyebrow: 'Privacy',
      title: 'Your data is yours',
      subtitle:
          'What ONO keeps, where it lives and who sees it. No ads, no selling, no tracking.',
      children: [
        const SizedBox(height: 14),
        OnoCard(
          child: Column(
            children: [
              _point(
                  Icons.phone_iphone_rounded,
                  'Where it lives',
                  system.syncsToCloud
                      ? 'On this phone, with a copy in your private cloud account so it survives a lost phone. Only your sign-in can read it (row-level security).'
                      : 'Only on this phone. Nothing leaves it unless you export a backup.'),
              _point(
                  Icons.event_note_outlined,
                  'Calendar',
                  'Meetings are read to plan your day and kept in memory only. They are never saved, exported or synced.'),
              _point(
                  Icons.favorite_border_rounded,
                  'Health',
                  'If you connect Apple Health, ONO saves one sleep and one vitals summary per night, the same way as your own logs. It never sends health data anywhere else.'),
              _point(
                  Icons.psychology_outlined,
                  'The weekly coach',
                  system.coachIsRemote
                      ? 'On Sundays your report, your profile (with your key people) and a summary of the week go to the coach to write your brief: scores, goals, growth, your Big 3, who you\'re overdue to contact, patterns, and your savings rate (never amounts). Notes, letters and journal entries are never sent.'
                      : 'Your Sunday brief is written on this phone. Nothing is sent.'),
              _point(
                  Icons.send_outlined,
                  'Nothing is sent for you',
                  'Progress notes, partner updates, coach reports, feedback asks and gratitude letters are copied for you to send yourself. ONO never messages anyone.'),
            ],
          ),
        ),
        const SectionHeader('What is stored'),
        Row(
          children: [
            Expanded(child: StatTile('${d.days}', 'days tracked')),
            Expanded(child: StatTile('${d.entries}', 'entries')),
            Expanded(child: StatTile('${d.health}', 'health entries')),
          ],
        ),
        const SizedBox(height: 14),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.ios_share_rounded,
                color: AppColors.steel,
                title: 'Export everything',
                subtitle: 'One JSON file — readable, and yours to keep or move',
                onTap: () async {
                  final json = system.exportJson();
                  try {
                    await Share.share(json,
                        subject: 'ONO backup ${dateKey(DateTime.now())}');
                  } catch (_) {
                    if (context.mounted) {
                      await copyText(context, json, message: 'Backup copied to clipboard');
                    }
                  }
                },
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.delete_forever_outlined,
                color: AppColors.danger,
                title: 'Delete everything',
                subtitle: system.syncsToCloud
                    ? 'From this phone and the cloud, for good'
                    : 'From this phone, for good',
                onTap: () => _erase(context, system),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
