import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

class EvidenceArchiveScreen extends StatelessWidget {
  const EvidenceArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final total = system.evidenceCount;

    return OnoPage(
      showBack: true,
      eyebrow: 'Playbook',
      title: 'Evidence Archive',
      subtitle:
          'The impostor forgets what you have built. This doesn\'t. Add at least 5 every Sunday, read it every Monday before the first meeting.',
      children: [
        const SizedBox(height: 20),
        OnoCard(
          child: Row(
            children: [
              ScoreRing(
                progress: total / 30,
                size: 52,
                color: AppColors.steel,
                center: Text('$total', style: AppText.number(size: 17)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$total items of proof', style: AppText.heading()),
                    const SizedBox(height: 2),
                    Text('Target: 10+ per section · 30+ by Day 16',
                        style: AppText.small()),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final section in evidenceSections)
          _Section(section: section),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final EvidencePrompt section;
  const _Section({required this.section});

  Future<void> _add(BuildContext context) async {
    final system = context.read<PersonalSystemProvider>();
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: AppText.title()),
            const SizedBox(height: 10),
            for (final p in section.prompts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $p', style: AppText.small()),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(
                  hintText: 'Be specific — what, where, the result.'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Add to archive'),
              ),
            ),
          ],
        ),
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      system.addEvidence(section.section, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final items = system.evidenceIn(section.section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('${section.title} · ${items.length}',
            action: '+ Add', onAction: () => _add(context)),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in section.prompts)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(p, style: AppText.small()),
                        ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _add(context),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Add the first one'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      Dismissible(
                        key: ValueKey(items[i].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger),
                        ),
                        onDismissed: (_) =>
                            system.removeEvidence(items[i].id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 26,
                                child: Text('${i + 1}',
                                    style: AppText.small(
                                            color: AppColors.steel)
                                        .copyWith(
                                            fontWeight: FontWeight.w700)),
                              ),
                              Expanded(
                                child: Text(items[i].text,
                                    style:
                                        AppText.body(color: AppColors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < items.length - 1) const Divider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
