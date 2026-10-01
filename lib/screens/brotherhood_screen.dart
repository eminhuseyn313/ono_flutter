import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/brotherhood.dart';
import '../providers/brotherhood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/squad_member_card.dart';

class BrotherhoodScreen extends StatefulWidget {
  const BrotherhoodScreen({super.key});

  @override
  State<BrotherhoodScreen> createState() => _BrotherhoodScreenState();
}

class _BrotherhoodScreenState extends State<BrotherhoodScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    final provider = context.read<BrotherhoodProvider>();
    provider.loadSquad().then((_) => _entranceController.forward());
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<BrotherhoodProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          final squad = provider.squad;
          if (squad == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No Squad Yet',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join a journey to be matched with your Brotherhood',
                    style: TextStyle(color: AppColors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── App bar ──
              SliverAppBar(
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'The Brotherhood',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
                floating: true,
              ),

              // ── Hero section ──
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _buildHeroSection(squad, provider),
                  ),
                ),
              ),

              // ── Members ──
              SliverToBoxAdapter(
                child: _buildMembersSection(squad, provider),
              ),

              // ── Squad Challenge ──
              if (provider.challenge != null)
                SliverToBoxAdapter(
                  child: _buildChallengeSection(provider.challenge!),
                ),

              // ── Activity Feed ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Activity',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final message = provider.messages[index];
                    return _buildMessageTile(message);
                  },
                  childCount: provider.messages.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(BrotherhoodSquad squad, BrotherhoodProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withValues(alpha: 0.2),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            squad.name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Week ${squad.weekNumber}',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statColumn('Members', '${squad.members.length}', '👥'),
              _statColumn(
                'Squad Streak',
                '${provider.squadStreak}',
                '🔥',
              ),
              _statColumn(
                'Behind',
                '${provider.membersBehind.length}',
                '⚠️',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(
    BrotherhoodSquad squad,
    BrotherhoodProvider provider,
  ) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        itemCount: squad.members.length,
        itemBuilder: (context, index) {
          final member = squad.members[index];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: SquadMemberCard(
              member: member,
              onSendEncouragement: () => provider.sendEncouragement(member.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengeSection(SquadChallenge challenge) {
    final progress = challenge.targetCompletions > 0
        ? challenge.currentCompletions / challenge.targetCompletions
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Text(
                'Squad Challenge',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDeadline(challenge.deadline),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge.title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: TextStyle(color: AppColors.grey, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.cardLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${challenge.currentCompletions} / ${challenge.targetCompletions} completions',
            style: TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          if (challenge.reward.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '🎁 ${challenge.reward}',
              style: TextStyle(
                color: AppColors.purpleSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageTile(SquadMessage message) {
    final icon = switch (message.type) {
      SquadMessageType.encouragement => '💪',
      SquadMessageType.milestone => '🎯',
      SquadMessageType.challengeComplete => '🏆',
      SquadMessageType.joined => '👋',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.anonymousName,
                  style: const TextStyle(
                    color: AppColors.purpleSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.message,
                  style: TextStyle(color: AppColors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            _timeAgo(message.timestamp),
            style: TextStyle(color: AppColors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return 'Ending soon';
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
