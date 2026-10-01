import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/council.dart';
import '../providers/council_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/council_response_card.dart';

class CouncilScreen extends StatefulWidget {
  const CouncilScreen({super.key});

  @override
  State<CouncilScreen> createState() => _CouncilScreenState();
}

class _CouncilScreenState extends State<CouncilScreen>
    with TickerProviderStateMixin {
  final _questionController = TextEditingController();
  late final TabController _tabController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouncilProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _tabController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _askCouncil() {
    final provider = context.read<CouncilProvider>();
    final question = _questionController.text.trim();
    if (question.isEmpty || provider.selectedMembers.length < 2) return;

    provider.askQuestion(question, provider.selectedMembers.toList());
    _questionController.clear();
  }

  void _resetForNewQuestion() {
    final provider = context.read<CouncilProvider>();
    provider.clearCurrentSession();
    provider.clearSelection();
    _questionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.background : AppColorsLight.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab bar ──
            _buildTabBar(isDark),
            // ── Tab views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCouncilTab(isDark),
                  _buildHistoryTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB BAR ────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.card.withValues(alpha: 0.5)
            : AppColorsLight.cardLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: isDark ? AppColors.white : AppColorsLight.white,
        unselectedLabelColor:
            isDark ? AppColors.grey : AppColorsLight.grey,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Council'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  // ─── COUNCIL TAB ────────────────────────────────────────────────────────

  Widget _buildCouncilTab(bool isDark) {
    return Consumer<CouncilProvider>(
      builder: (context, provider, _) {
        if (provider.isAsking) {
          return _buildLoadingState(provider, isDark);
        }
        if (provider.currentSession != null) {
          return _buildResponseState(provider, isDark);
        }
        return _buildInputState(provider, isDark);
      },
    );
  }

  // ─── INPUT STATE ────────────────────────────────────────────────────────

  Widget _buildInputState(CouncilProvider provider, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        _buildHeroSection(isDark),
        const SizedBox(height: 28),
        _buildMemberGrid(provider, isDark),
        const SizedBox(height: 24),
        _buildQuestionInput(isDark),
        const SizedBox(height: 20),
        _buildAskButton(provider, isDark),
        const SizedBox(height: 16),
        if (provider.quota != null) _buildQuotaDisplay(provider, isDark),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── HERO SECTION ───────────────────────────────────────────────────────

  Widget _buildHeroSection(bool isDark) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity = 0.15 + (_glowController.value * 0.15);
        return Column(
          children: [
            // Glow behind title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: glowOpacity),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🔮',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.purple,
                        AppColors.purpleSoft,
                        AppColors.cyan,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'The Council',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Summon the wisdom of legends',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.grey : AppColorsLight.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── MEMBER SELECTION GRID ──────────────────────────────────────────────

  Widget _buildMemberGrid(CouncilProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Choose Your Council',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColorsLight.white,
              ),
            ),
            const Spacer(),
            Text(
              '${provider.selectedMembers.length}/4 selected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: provider.selectedMembers.length >= 2
                    ? AppColors.green
                    : isDark
                        ? AppColors.grey
                        : AppColorsLight.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Select 2-4 members to hear their perspectives',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.grey : AppColorsLight.grey,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: CouncilMember.all.length,
          itemBuilder: (context, index) {
            final member = CouncilMember.all[index];
            final isSelected = provider.isMemberSelected(member.roleModelId);
            final canSelect =
                provider.selectedMembers.length < 4 || isSelected;

            return GestureDetector(
              onTap: canSelect
                  ? () => provider.toggleMember(member.roleModelId)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.purple.withValues(alpha: 0.2)
                            : isDark
                                ? AppColors.card
                                : AppColorsLight.cardLight,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.purple
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.purple.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        member.avatarEmoji,
                        style: TextStyle(
                          fontSize: 24,
                          color: canSelect
                              ? null
                              : (isDark ? AppColors.grey : AppColorsLight.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Name
                    Text(
                      member.name.split(' ').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.purple
                            : (isDark ? AppColors.grey : AppColorsLight.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── QUESTION INPUT ─────────────────────────────────────────────────────

  Widget _buildQuestionInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Question',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColorsLight.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.7),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? AppColors.divider
                  : AppColorsLight.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _questionController,
                maxLength: 500,
                maxLines: 4,
                minLines: 3,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.white : AppColorsLight.white,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'What challenge are you facing? What decision do you need guidance on?',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.grey.withValues(alpha: 0.6)
                        : AppColorsLight.grey.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              // Character count
              Padding(
                padding:
                    const EdgeInsets.only(right: 16, bottom: 10, left: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_questionController.text.length}/500',
                    style: TextStyle(
                      fontSize: 12,
                      color: _questionController.text.length > 450
                          ? AppColors.warning
                          : (isDark ? AppColors.grey : AppColorsLight.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ASK BUTTON ─────────────────────────────────────────────────────────

  Widget _buildAskButton(CouncilProvider provider, bool isDark) {
    final isEnabled = provider.selectedMembers.length >= 2 &&
        _questionController.text.trim().isNotEmpty &&
        (provider.quota?.canAsk ?? true);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? _askCouncil : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? AppColors.purple : AppColors.purple.withValues(alpha: 0.3),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
          elevation: isEnabled ? 4 : 0,
          shadowColor: AppColors.purple.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🔮',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Ask The Council',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUOTA DISPLAY ──────────────────────────────────────────────────────

  Widget _buildQuotaDisplay(CouncilProvider provider, bool isDark) {
    final quota = provider.quota!;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.card.withValues(alpha: 0.5)
              : AppColorsLight.cardLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          quota.canAsk
              ? '${quota.remaining} question${quota.remaining == 1 ? '' : 's'} remaining today'
              : 'Daily limit reached. Resets at midnight.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: quota.canAsk
                ? (isDark ? AppColors.grey : AppColorsLight.grey)
                : AppColors.warning,
          ),
        ),
      ),
    );
  }

  // ─── LOADING STATE ──────────────────────────────────────────────────────

  Widget _buildLoadingState(CouncilProvider provider, bool isDark) {
    final selectedIds = provider.selectedMembers.toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'The Council is deliberating...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColorsLight.white,
              ),
            ),
            const SizedBox(height: 32),
            ...List.generate(selectedIds.length, (index) {
              final member = CouncilMember.findById(selectedIds[index]);
              if (member == null) return const SizedBox.shrink();

              return _ThinkingIndicator(
                member: member,
                delay: index * 400,
                isDark: isDark,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── RESPONSE STATE ─────────────────────────────────────────────────────

  Widget _buildResponseState(CouncilProvider provider, bool isDark) {
    final session = provider.currentSession!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        // Question recap
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Question',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                session.question,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.white : AppColorsLight.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Responses
        ...List.generate(session.responses.length, (index) {
          return CouncilResponseCard(
            response: session.responses[index],
            animationDelay: index * 300,
          );
        }),
        const SizedBox(height: 16),
        // Actions row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetForNewQuestion,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Ask Another'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  side: BorderSide(
                    color: AppColors.purple.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Favorite button
            Container(
              decoration: BoxDecoration(
                color: session.isFavorited
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : (isDark
                        ? AppColors.card
                        : AppColorsLight.cardLight),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: session.isFavorited
                      ? AppColors.warning.withValues(alpha: 0.3)
                      : (isDark
                          ? AppColors.divider
                          : AppColorsLight.divider),
                ),
              ),
              child: IconButton(
                onPressed: () => provider.toggleFavorite(session.id),
                icon: Icon(
                  session.isFavorited
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: session.isFavorited
                      ? AppColors.warning
                      : (isDark ? AppColors.grey : AppColorsLight.grey),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.quota != null) _buildQuotaDisplay(provider, isDark),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── HISTORY TAB ────────────────────────────────────────────────────────

  Widget _buildHistoryTab(bool isDark) {
    return Consumer<CouncilProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingHistory) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📜', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No sessions yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColorsLight.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask The Council your first question',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.grey : AppColorsLight.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: provider.history.length,
          itemBuilder: (context, index) {
            final session = provider.history[index];
            return _buildHistoryItem(session, provider, isDark);
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(
    CouncilSession session,
    CouncilProvider provider,
    bool isDark,
  ) {
    final memberEmojis = session.responses
        .map((r) => CouncilMember.findById(r.memberId)?.avatarEmoji ?? '🔮')
        .toList();

    final timeAgo = _formatTimeAgo(session.createdAt);

    return GestureDetector(
      onTap: () {
        provider.viewSession(session);
        _tabController.animateTo(0);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColorsLight.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.divider : AppColorsLight.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Member emojis
                ...memberEmojis.map((emoji) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    )),
                const Spacer(),
                if (session.isFavorited)
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                const SizedBox(width: 6),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.grey : AppColorsLight.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              session.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColorsLight.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${session.responses.length} response${session.responses.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.grey : AppColorsLight.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ─── THINKING INDICATOR ───────────────────────────────────────────────────

class _ThinkingIndicator extends StatefulWidget {
  final CouncilMember member;
  final int delay;
  final bool isDark;

  const _ThinkingIndicator({
    required this.member,
    required this.delay,
    required this.isDark,
  });

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _pulse;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox(height: 60);

    return FadeTransition(
      opacity: _fadeIn,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Opacity(
            opacity: _pulse.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.card.withValues(alpha: 0.6)
                    : AppColorsLight.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.member.avatarEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.member.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? AppColors.white
                          : AppColorsLight.white,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 32,
                    child: _buildDots(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset =
                sin((_controller.value * 2 * pi) + (i * pi / 3));
            return Transform.translate(
              offset: Offset(0, offset * 3),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
