// widgets/forge_checklist_block.dart — Interactive checklist block

import 'package:flutter/material.dart';

import '../models/forge.dart';

class ForgeChecklistBlock extends StatefulWidget {
  final ForgeBlock block;
  final void Function(int index)? onToggle;

  const ForgeChecklistBlock({
    super.key,
    required this.block,
    this.onToggle,
  });

  @override
  State<ForgeChecklistBlock> createState() => _ForgeChecklistBlockState();
}

class _ForgeChecklistBlockState extends State<ForgeChecklistBlock> {
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    final items = widget.block.checklistItems ?? [];
    final existing = widget.block.checklistChecked ?? [];
    _checked = List.generate(
      items.length,
      (i) => i < existing.length ? existing[i] : false,
    );
  }

  void _toggle(int index) {
    setState(() {
      _checked[index] = !_checked[index];
    });
    widget.onToggle?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.block.checklistItems ?? [];
    final completedCount = _checked.where((c) => c).length;
    final allDone = completedCount == items.length && items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? (allDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.3))
              : (allDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (allDone
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  allDone
                      ? Icons.check_circle
                      : Icons.checklist,
                  color: allDone
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.block.title ?? 'Checklist',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (allDone
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completedCount/${items.length}',
                  style: TextStyle(
                    color: allDone
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Content
          if (widget.block.content != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.block.content!,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 13,
              ),
            ),
          ],

          // Progress bar
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: items.isEmpty ? 0 : completedCount / items.length,
              minHeight: 5,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),

          // Items
          const SizedBox(height: 12),
          ...List.generate(items.length, (i) {
            final checked = _checked[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _toggle(i),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: checked
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: checked
                              ? const Color(0xFF10B981)
                              : isDark
                                  ? const Color(0xFF3A3C4E)
                                  : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: checked
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i],
                        style: TextStyle(
                          color: checked
                              ? (isDark
                                  ? Colors.white38
                                  : Colors.black38)
                              : (isDark
                                  ? Colors.white
                                  : Colors.black87),
                          fontSize: 14,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: isDark
                              ? Colors.white38
                              : Colors.black38,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
