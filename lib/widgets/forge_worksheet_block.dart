// widgets/forge_worksheet_block.dart — Interactive worksheet block

import 'package:flutter/material.dart';

import '../models/forge.dart';

class ForgeWorksheetBlock extends StatefulWidget {
  final ForgeBlock block;
  final void Function(List<String> answers)? onSubmit;

  const ForgeWorksheetBlock({
    super.key,
    required this.block,
    this.onSubmit,
  });

  @override
  State<ForgeWorksheetBlock> createState() => _ForgeWorksheetBlockState();
}

class _ForgeWorksheetBlockState extends State<ForgeWorksheetBlock> {
  late List<TextEditingController> _controllers;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final blanks = widget.block.worksheetBlanks ?? [];
    final answers = widget.block.worksheetAnswers ?? [];
    _controllers = List.generate(
      blanks.length,
      (i) => TextEditingController(
        text: i < answers.length ? answers[i] : '',
      ),
    );
    _submitted = answers.isNotEmpty && answers.every((a) => a.isNotEmpty);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final answers = _controllers.map((c) => c.text.trim()).toList();
    if (answers.any((a) => a.isEmpty)) return;

    setState(() => _submitted = true);
    widget.onSubmit?.call(answers);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blanks = widget.block.worksheetBlanks ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF06B6D4).withValues(alpha: 0.3)
              : const Color(0xFF06B6D4).withValues(alpha: 0.15),
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
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Color(0xFF06B6D4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.block.title ?? 'Worksheet',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_submitted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Done',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Content/instructions
          if (widget.block.content != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.block.content!,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],

          // Blanks
          const SizedBox(height: 14),
          ...List.generate(blanks.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blanks[i],
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _controllers[i],
                    enabled: !_submitted,
                    maxLines: 2,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your answer...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A2C3E)
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Submit button
          if (!_submitted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Submit Answers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
