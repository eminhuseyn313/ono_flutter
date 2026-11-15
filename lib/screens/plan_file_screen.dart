import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/emin_system.dart';
import '../data/plan_import.dart';
import '../providers/personal_system_provider.dart';
import '../router.dart' show appRoutes;
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Your full plan: have any AI tool write one from a prompt that carries
/// what you told ONO, then load the file (or paste the answer). It adds a
/// day, training, reading, films, practices, growth areas, monthly themes
/// and coach notes to what you set up; what you logged never changes.
class PlanFileScreen extends StatefulWidget {
  const PlanFileScreen({super.key});

  @override
  State<PlanFileScreen> createState() => _PlanFileScreenState();
}

class _PlanFileScreenState extends State<PlanFileScreen> {
  final _text = TextEditingController();
  PlanImportResult? _result;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  static bool _routeOk(String r) {
    final path = r.split('?').first;
    return appRoutes.contains(r) || appRoutes.contains(path) || appRoutes.any((a) => a.split('?').first == path);
  }

  void _load(PersonalSystemProvider system, String text) {
    final r = system.importPlanText(text, routeOk: _routeOk);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _result = r);
    if (r.ok) _text.clear();
  }

  Future<void> _pickFile(PersonalSystemProvider system) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt', 'md'],
        withData: true,
      );
      final bytes = picked?.files.single.bytes;
      if (bytes == null || !mounted) return;
      _load(system, utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      if (mounted) toast(context, 'Couldn\'t open that file. Paste its text below instead.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final loaded = system.hasPersonalPlan;
    final r = _result;
    return OnoPage(
      showBack: true,
      eyebrow: 'Your full plan',
      title: loaded ? 'Your plan is loaded' : 'Get a full plan, made for you',
      subtitle: loaded
          ? 'Made for ${plan.profile?.name ?? 'you'}. It lives in your data, syncs to your devices and travels with your backups.'
          : 'Have any AI tool you use (ChatGPT, Claude, Gemini…) write a plan for your life: your day, training, books and films, practices, the skills you\'re growing and monthly themes. Then load it here.',
      children: [
        if (r != null) ...[
          const SizedBox(height: 10),
          OnoCard(
            key: const Key('plan-report'),
            color: r.ok ? AppColors.accentDeep : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.ok ? 'Loaded' : 'Not loaded', style: AppText.heading()),
                const SizedBox(height: 6),
                if (!r.ok) Text(r.error!, style: AppText.body(color: AppColors.white)),
                for (final l in r.loaded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• $l', style: AppText.small(color: AppColors.white)),
                  ),
                if (r.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Adjusted', style: AppText.eyebrow()),
                  for (final w in r.warnings)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(w, style: AppText.small()),
                    ),
                ],
                if (r.ok && system.canUndoPlanImport)
                  TextButton(
                    key: const Key('plan-undo'),
                    onPressed: () {
                      system.undoPlanImport();
                      setState(() => _result = null);
                      toast(context, 'Back to what you had before.');
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Undo'),
                  ),
              ],
            ),
          ),
        ],
        SectionHeader(loaded ? 'Make a new one' : '1 · Ask an AI'),
        Text(
            'Copy the prompt and paste it into the AI. It already says what you told ONO (your name, roles, life wheel, goals, daily items and your day), asks you a few questions, then writes the plan in ONO\'s format. Nothing is sent from here: you paste it yourself.',
            style: AppText.small()),
        const SizedBox(height: 10),
        GhostButton('Copy the prompt', icon: Icons.copy_rounded, onPressed: () {
          Clipboard.setData(ClipboardData(text: system.planPromptText()));
          toast(context, 'Copied. Paste it into your AI tool.');
        }),
        SectionHeader(loaded ? 'Load a new version' : '2 · Load the answer'),
        Text('Save the AI\'s answer as a file, or copy all of it. Text around the plan is fine.',
            style: AppText.small()),
        const SizedBox(height: 10),
        PrimaryButton('Choose a file', icon: Icons.file_open_outlined, onPressed: () => _pickFile(system)),
        const SizedBox(height: 12),
        TextField(
          key: const Key('plan-paste'),
          controller: _text,
          minLines: 3,
          maxLines: 8,
          style: AppText.small(color: AppColors.white),
          decoration: const InputDecoration(hintText: '…or paste the answer here'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        GhostButton('Load what I pasted',
            icon: Icons.download_done_rounded,
            onPressed: _text.text.trim().isEmpty ? null : () => _load(system, _text.text)),
        if (loaded) ...[
          const SectionHeader('Keep it safe'),
          Text('Your plan syncs with your account. A copy of your own is good too.', style: AppText.small()),
          const SizedBox(height: 10),
          GhostButton('Save the plan as a file', icon: Icons.ios_share_rounded, onPressed: () async {
            final t = system.planText();
            if (t == null) return;
            final name = (plan.profile?.firstName ?? 'my').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
            try {
              await Share.shareXFiles([
                XFile.fromData(Uint8List.fromList(utf8.encode(t)), mimeType: 'application/json', name: 'ono_plan_$name.json')
              ], subject: 'My ONO plan');
            } catch (_) {
              await Clipboard.setData(ClipboardData(text: t));
              if (context.mounted) toast(context, 'Copied the plan instead — paste it into a note to keep.');
            }
          }),
          const SizedBox(height: 8),
          GhostButton('Remove the plan', icon: Icons.remove_circle_outline_rounded, onPressed: () async {
            final sure = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remove the plan?'),
                content: const Text(
                    'ONO goes back to what you set up yourself. Everything you logged stays. Save the plan first if you may want it back.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep it')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
                ],
              ),
            );
            if (sure == true) {
              system.setPersonalPlan(null);
              if (context.mounted) toast(context, 'Removed.');
            }
          }),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
