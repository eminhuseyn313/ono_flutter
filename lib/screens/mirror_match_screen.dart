import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mirror_match.dart';
import '../providers/mirror_match_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/trajectory_chart.dart';

class MirrorMatchScreen extends StatefulWidget {
  const MirrorMatchScreen({super.key});

  @override
  State<MirrorMatchScreen> createState() => _MirrorMatchScreenState();
}

class _MirrorMatchScreenState extends State<MirrorMatchScreen> {
  final _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MirrorMatchProvider>().load();
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mirror Match',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<MirrorMatchProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (!provider.hasMatch) {
            return _buildSearching(provider);
          }

          return _buildMatched(provider);
        },
      ),
    );
  }

  Widget _buildSearching(MirrorMatchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪞', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Finding Your Mirror',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Searching for someone who started where you are '
              'and is now further along the journey...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: provider.loading ? null : () => provider.findMatch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: provider.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Search Now',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatched(MirrorMatchProvider provider) {
    final mirror = provider.mirror!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // ── Mirror profile hero ──
        _buildMirrorHero(mirror, provider),
        const SizedBox(height: 24),

        // ── Path Proof chart ──
        _buildSectionLabel('📈 Path Proof'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Their trajectory from Day 1 — they started just like you.',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TrajectoryChart(
                myPoints: provider.myTrajectory,
                mirrorPoints: mirror.trajectory,
                height: 220,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Stats comparison ──
        _buildSectionLabel('⚡ Where They Are Now'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard('🔥', '${mirror.currentStreak}', 'Streak')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('🏆', '${mirror.legacyScore}', 'Legacy')),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '📊',
                '+${(mirror.totalGrowth * 100).round()}%',
                'Growth',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Chat section ──
        if (provider.chatUnlocked) ...[
          _buildSectionLabel('💬 Anonymous Chat'),
          const SizedBox(height: 8),
          _buildChat(provider),
        ] else ...[
          _buildChatLocked(),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMirrorHero(MirrorProfile mirror, MirrorMatchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(mirror.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mirror.alias,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.similarityPercent}% similar start · '
                  '${mirror.daysAhead} days ahead',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Strongest: ${_laneLabel(mirror.strongestLane)}',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat(MirrorMatchProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Messages
          ...provider.messages.map((msg) => _buildMessage(msg)),

          // Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Send encouragement...',
                      hintStyle: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final text = _msgController.text;
                    if (text.trim().isNotEmpty) {
                      provider.sendMessage(text);
                      _msgController.clear();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send, color: AppColors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(MirrorMessage msg) {
    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.purple.withValues(alpha: 0.2)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: isMe ? AppColors.white : AppColors.grey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatLocked() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, color: AppColors.grey.withValues(alpha: 0.4), size: 32),
          const SizedBox(height: 12),
          const Text(
            'Chat Unlocks at Day 7',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stay matched for 7 days to unlock anonymous 1:1 chat with your mirror.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _laneLabel(String lane) => switch (lane) {
        'mind' => '🧠 Mind',
        'body' => '💪 Body',
        'social' => '👥 Social',
        'skill' => '🎯 Skill',
        _ => lane,
      };
}
