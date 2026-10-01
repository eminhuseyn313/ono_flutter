import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/community_challenge.dart';
import '../providers/community_challenge_provider.dart';
import '../widgets/challenge_card.dart';
import '../widgets/challenge_leaderboard.dart';

class CommunityChallengeScreen extends StatefulWidget {
  const CommunityChallengeScreen({super.key});

  @override
  State<CommunityChallengeScreen> createState() =>
      _CommunityChallengeScreenState();
}

class _CommunityChallengeScreenState extends State<CommunityChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityChallengeProvider>().loadChallenges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Challenges',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.purple,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.purple,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<CommunityChallengeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.challengeData == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.challengeData == null) {
            return Center(
              child: Text(
                'No challenges available',
                style: GoogleFonts.plusJakartaSans(color: AppColors.grey),
              ),
            );
          }

          return Column(
            children: [
              // Stats bar
              _buildStatsBar(provider),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChallengeList(
                        provider.activeChallenges, provider, 'active'),
                    _buildChallengeList(
                        provider.upcomingChallenges, provider, 'upcoming'),
                    _buildChallengeList(
                        provider.completedChallenges, provider, 'completed'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(CommunityChallengeProvider provider) {
    final data = provider.challengeData!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('${data.totalParticipants}', 'Total Players',
              AppColors.purple),
          Container(
            width: 1,
            height: 30,
            color: AppColors.divider,
          ),
          _buildStat(
              '${data.activeChallenges}', 'Active', AppColors.green),
          Container(
            width: 1,
            height: 30,
            color: AppColors.divider,
          ),
          _buildStat('${provider.myChallenges.length}', 'Joined',
              AppColors.cyan),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeList(List<CommunityChallenge> challenges,
      CommunityChallengeProvider provider, String type) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'active'
                  ? Icons.emoji_events
                  : type == 'upcoming'
                      ? Icons.event
                      : Icons.check_circle,
              color: AppColors.grey,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              type == 'active'
                  ? 'No active challenges'
                  : type == 'upcoming'
                      ? 'No upcoming challenges'
                      : 'No completed challenges yet',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type == 'active'
                  ? 'New challenges drop every week!'
                  : type == 'upcoming'
                      ? 'Check back soon for new challenges.'
                      : 'Join a challenge to get started!',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.purple,
      backgroundColor: AppColors.card,
      onRefresh: () => provider.loadChallenges(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChallengeCard(
              challenge: challenge,
              onTap: () => _showChallengeDetail(challenge, provider),
              onJoin: () => provider.joinChallenge(challenge.id),
              onLeave: () => provider.leaveChallenge(challenge.id),
            ),
          );
        },
      ),
    );
  }

  void _showChallengeDetail(
      CommunityChallenge challenge, CommunityChallengeProvider provider) {
    provider.loadLeaderboard(challenge.id);
    final laneColor = Color(challenge.laneColorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: laneColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.emoji_events,
                                  color: laneColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challenge.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              laneColor.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          challenge.lane,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: laneColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        challenge.type.label,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Description
                        Text(
                          challenge.description,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.greyLight,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Target and reward info
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                Icons.flag,
                                'Target',
                                '${challenge.targetValue} ${challenge.targetUnit}',
                                laneColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildInfoCard(
                                Icons.people,
                                'Participants',
                                '${challenge.participantCount}',
                                AppColors.cyan,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildInfoCard(
                                Icons.schedule,
                                'Remaining',
                                challenge.status == ChallengeStatus.completed
                                    ? 'Ended'
                                    : '${challenge.daysRemaining}d',
                                AppColors.warning,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Reward card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warning.withValues(alpha: 0.1),
                                AppColors.card,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star,
                                  color: AppColors.warning, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reward',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      challenge.reward,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Leaderboard
                        Consumer<CommunityChallengeProvider>(
                          builder: (context, p, _) {
                            return ChallengeLeaderboard(
                              participants: p.leaderboard,
                              myRank: challenge.myRank,
                              accentColor: laneColor,
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Join/Leave button
                        if (challenge.status != ChallengeStatus.completed)
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () {
                                if (challenge.isJoined) {
                                  provider.leaveChallenge(challenge.id);
                                } else {
                                  provider.joinChallenge(challenge.id);
                                }
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: challenge.isJoined
                                      ? AppColors.card
                                      : laneColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: challenge.isJoined
                                      ? Border.all(color: AppColors.divider)
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    challenge.isJoined
                                        ? 'Leave Challenge'
                                        : 'Join Challenge',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: challenge.isJoined
                                          ? AppColors.grey
                                          : AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
