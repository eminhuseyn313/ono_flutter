import 'dart:async';

import 'package:flutter/material.dart';

import '../models/forge.dart';
import '../theme/app_theme.dart';
import 'forge_audio_block.dart';
import 'forge_worksheet_block.dart';
import 'forge_checklist_block.dart';

/// Renders a single ForgeBlock based on its type:
/// text, scenario, timedExercise, multipleChoice, reflection, keyTakeaway,
/// audio, worksheet, checklist, quote.
class ForgeBlockWidget extends StatefulWidget {
  final ForgeBlock block;
  final ValueChanged<int?> onAnswer;

  const ForgeBlockWidget({
    super.key,
    required this.block,
    required this.onAnswer,
  });

  @override
  State<ForgeBlockWidget> createState() => _ForgeBlockWidgetState();
}

class _ForgeBlockWidgetState extends State<ForgeBlockWidget> {
  int? _selectedChoice;
  bool _showExplanation = false;
  int _timerSeconds = 0;
  Timer? _timer;
  bool _timerComplete = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.block.type) {
      ForgeBlockType.text => _buildText(),
      ForgeBlockType.scenario => _buildScenario(),
      ForgeBlockType.timedExercise => _buildTimedExercise(),
      ForgeBlockType.multipleChoice => _buildMultipleChoice(),
      ForgeBlockType.reflection => _buildReflection(),
      ForgeBlockType.keyTakeaway => _buildKeyTakeaway(),
      ForgeBlockType.audio => ForgeAudioBlock(block: widget.block),
      ForgeBlockType.worksheet => ForgeWorksheetBlock(block: widget.block),
      ForgeBlockType.checklist => ForgeChecklistBlock(block: widget.block),
      ForgeBlockType.quote => _buildQuote(),
    };
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blockTitle(widget.block.title ?? ''),
        const SizedBox(height: 12),
        Text(
          widget.block.content ?? '',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildScenario() {
    final choices = widget.block.choices ?? [];
    final correct = widget.block.correctChoice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blockBadge('💡 Scenario', AppColors.warning),
        const SizedBox(height: 12),
        _blockTitle(widget.block.title ?? ''),
        const SizedBox(height: 8),
        Text(
          widget.block.content ?? '',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(choices.length, (i) {
          final isSelected = _selectedChoice == i;
          final isCorrect = i == correct;
          final showResult = _showExplanation;

          Color bgColor = AppColors.card;
          Color borderColor = AppColors.divider;
          if (showResult && isCorrect) {
            bgColor = AppColors.green.withValues(alpha: 0.1);
            borderColor = AppColors.green.withValues(alpha: 0.4);
          } else if (showResult && isSelected && !isCorrect) {
            bgColor = const Color(0xFFE0605A).withValues(alpha: 0.1);
            borderColor = const Color(0xFFE0605A).withValues(alpha: 0.4);
          } else if (isSelected) {
            bgColor = AppColors.purple.withValues(alpha: 0.1);
            borderColor = AppColors.purple;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _showExplanation
                  ? null
                  : () {
                      setState(() {
                        _selectedChoice = i;
                        _showExplanation = true;
                      });
                      widget.onAnswer(i);
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        choices[i],
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (showResult && isCorrect)
                      const Icon(Icons.check_circle,
                          color: AppColors.green, size: 20),
                    if (showResult && isSelected && !isCorrect)
                      const Icon(Icons.cancel,
                          color: Color(0xFFE0605A), size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_showExplanation && widget.block.explanation != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Text(
              widget.block.explanation!,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimedExercise() {
    final duration = widget.block.durationSeconds ?? 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blockBadge('⏱️ Exercise', AppColors.green),
        const SizedBox(height: 12),
        _blockTitle(widget.block.title ?? ''),
        const SizedBox(height: 8),
        Text(
          widget.block.content ?? '',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        if (widget.block.instruction != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.block.instruction!,
            style: TextStyle(
              color: AppColors.purple.withValues(alpha: 0.8),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Timer
        Center(
          child: Column(
            children: [
              Text(
                _timerComplete
                    ? '✓ Done'
                    : _timer != null
                        ? _formatTime(duration - _timerSeconds)
                        : _formatTime(duration),
                style: TextStyle(
                  color: _timerComplete ? AppColors.green : AppColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 16),
              if (!_timerComplete)
                ElevatedButton(
                  onPressed: _timer != null ? null : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _timer != null ? 'In Progress...' : 'Start Timer',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _startTimer() {
    final duration = widget.block.durationSeconds ?? 60;
    setState(() => _timerSeconds = 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timerSeconds++);
      if (_timerSeconds >= duration) {
        t.cancel();
        setState(() => _timerComplete = true);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildMultipleChoice() {
    final options = widget.block.options ?? [];
    final correct = widget.block.correctOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blockBadge('❓ Quick Check', AppColors.cyan),
        const SizedBox(height: 12),
        _blockTitle(widget.block.title ?? ''),
        const SizedBox(height: 8),
        Text(
          widget.block.content ?? '',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(options.length, (i) {
          final isSelected = _selectedChoice == i;
          final isCorrect = i == correct;
          final answered = _selectedChoice != null;

          Color bgColor = AppColors.card;
          Color borderColor = AppColors.divider;
          if (answered && isCorrect) {
            bgColor = AppColors.green.withValues(alpha: 0.1);
            borderColor = AppColors.green.withValues(alpha: 0.4);
          } else if (answered && isSelected && !isCorrect) {
            bgColor = const Color(0xFFE0605A).withValues(alpha: 0.1);
            borderColor = const Color(0xFFE0605A).withValues(alpha: 0.4);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: answered
                  ? null
                  : () {
                      setState(() => _selectedChoice = i);
                      widget.onAnswer(i);
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReflection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blockBadge('📝 Reflection', AppColors.purple),
        const SizedBox(height: 12),
        _blockTitle(widget.block.title ?? ''),
        const SizedBox(height: 8),
        Text(
          widget.block.content ?? '',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          maxLines: 4,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Write your thoughts...',
            hintStyle:
                TextStyle(color: AppColors.grey.withValues(alpha: 0.4)),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.purple),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyTakeaway() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleSoft.withValues(alpha: 0.12),
            AppColors.purple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔑', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Key Takeaway',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.block.content ?? '',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💬',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 12),
          Text(
            widget.block.content ?? '',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          if (widget.block.quoteAuthor != null) ...[
            const SizedBox(height: 10),
            Text(
              '— ${widget.block.quoteAuthor}',
              style: TextStyle(
                color: AppColors.purple,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _blockTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _blockBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
