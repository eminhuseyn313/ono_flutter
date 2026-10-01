import 'package:flutter/material.dart';

import '../data/emin_system.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

class ProtocolsScreen extends StatelessWidget {
  const ProtocolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnoPage(
      showBack: true,
      eyebrow: 'Playbook',
      title: 'Protocols',
      subtitle:
          'Evidence-based tools for the exact moments that used to go wrong.',
      children: [
        const SizedBox(height: 20),
        for (final p in protocols)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProtocolCard(protocol: p),
          ),
      ],
    );
  }
}

class _ProtocolCard extends StatefulWidget {
  final Protocol protocol;
  const _ProtocolCard({required this.protocol});

  @override
  State<_ProtocolCard> createState() => _ProtocolCardState();
}

class _ProtocolCardState extends State<_ProtocolCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.protocol;
    final color = AppColors.lane(p.lane);
    return OnoCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(p.icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppText.heading()),
                    const SizedBox(height: 2),
                    Text(p.source, style: AppText.small()),
                  ],
                ),
              ),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.what, style: AppText.body(color: AppColors.white)),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const Divider(),
                KeyValueRow('When', p.when, labelWidth: 64),
                KeyValueRow('Why', p.why, labelWidth: 64),
                if (p.before != null && p.after != null) ...[
                  const SizedBox(height: 10),
                  _Example(
                      label: 'BEFORE',
                      text: p.before!,
                      color: AppColors.danger),
                  const SizedBox(height: 8),
                  _Example(
                      label: 'AFTER', text: p.after!, color: AppColors.body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Example extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _Example(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.eyebrow(color: color)),
            const SizedBox(height: 6),
            Text('"$text"', style: AppText.body(color: AppColors.greyLight)),
          ],
        ),
      );
}
