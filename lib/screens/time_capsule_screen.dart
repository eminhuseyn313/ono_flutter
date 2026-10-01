import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/time_capsule.dart';
import '../providers/time_capsule_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/create_capsule_sheet.dart';
import '../widgets/time_capsule_card.dart';

class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({super.key});

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0=Sealed, 1=Ready, 2=Opened

  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScale;

  // TODO: replace with real auth user id
  static const _userId = 'user_1';

  @override
  void initState() {
    super.initState();

    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScale = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimeCapsuleProvider>().loadCapsules(_userId);
      _fabAnimController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  List<TimeCapsule> _capsulesForTab(TimeCapsuleProvider provider) {
    switch (_selectedTab) {
      case 0:
        return provider.locked;
      case 1:
        return provider.unlockedUnopened;
      case 2:
        return provider.opened;
      default:
        return provider.capsules;
    }
  }

  int _countForTab(TimeCapsuleProvider provider, int tab) {
    switch (tab) {
      case 0:
        return provider.locked.length;
      case 1:
        return provider.unlockedUnopened.length;
      case 2:
        return provider.opened.length;
      default:
        return 0;
    }
  }

  void _showCreateSheet() {
    HapticFeedback.mediumImpact();
    final provider = context.read<TimeCapsuleProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCapsuleSheet(
        onCreateCapsule: ({
          required String message,
          String? lane,
          required DateTime unlockAt,
          String? mood,
        }) {
          return provider.createCapsule(
            _userId,
            message: message,
            lane: lane,
            unlockAt: unlockAt,
            mood: mood,
          );
        },
      ),
    );
  }

  void _openCapsule(TimeCapsule capsule) async {
    if (!capsule.isUnlocked || capsule.isOpened) return;

    HapticFeedback.heavyImpact();

    // Show dramatic reveal dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CapsuleRevealDialog(capsule: capsule),
    );

    if (confirmed == true && mounted) {
      await context.read<TimeCapsuleProvider>().openCapsule(_userId, capsule.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.purple.withValues(alpha: 0.08),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildTabRow(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: _showCreateSheet,
          backgroundColor: AppColors.purple,
          elevation: 8,
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer<TimeCapsuleProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                '✉️',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'Time Capsules',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (provider.totalCapsules > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${provider.totalCapsules}',
                    style: const TextStyle(
                      color: AppColors.purpleSoft,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabRow() {
    return Consumer<TimeCapsuleProvider>(
      builder: (context, provider, _) {
        final tabs = [
          ('Sealed 🔒', 0),
          ('Ready ✨', 1),
          ('Opened 📖', 2),
        ];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: tabs.map((tab) {
              final label = tab.$1;
              final index = tab.$2;
              final count = _countForTab(provider, index);
              final isSelected = _selectedTab == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTab = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.purple.withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.purple.withValues(alpha: 0.4),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.grey,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.purple
                                  : AppColors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<TimeCapsuleProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '😔',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => provider.loadCapsules(_userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final items = _capsulesForTab(provider);

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return TimeCapsuleCard(
              capsule: items[index],
              onTap: () => _openCapsule(items[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String emoji;
    String title;
    String subtitle;

    switch (_selectedTab) {
      case 0:
        emoji = '✉️';
        title = 'No sealed capsules';
        subtitle =
            'Write a letter to your future self.\nTap + to create your first time capsule.';
        break;
      case 1:
        emoji = '⏳';
        title = 'Nothing ready yet';
        subtitle =
            'Your sealed capsules will appear here\nonce their unlock date arrives.';
        break;
      case 2:
        emoji = '📭';
        title = 'No opened capsules';
        subtitle =
            'Letters you\'ve read will live here\nas reminders of how far you\'ve come.';
        break;
      default:
        emoji = '✉️';
        title = 'No capsules';
        subtitle = 'Create your first time capsule.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// DRAMATIC REVEAL DIALOG
// ──────────────────────────────────────────
class _CapsuleRevealDialog extends StatefulWidget {
  final TimeCapsule capsule;

  const _CapsuleRevealDialog({required this.capsule});

  @override
  State<_CapsuleRevealDialog> createState() => _CapsuleRevealDialogState();
}

class _CapsuleRevealDialogState extends State<_CapsuleRevealDialog>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scale;

  late final AnimationController _contentController;
  late final Animation<double> _contentFade;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeIn,
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _reveal() {
    HapticFeedback.heavyImpact();
    setState(() => _revealed = true);
    _contentController.forward();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.card,
                    AppColors.card.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_revealed) ...[
                    const Text('✨', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'A letter from your past self',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Written on ${_formatDate(widget.capsule.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.capsule.mood != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'You were feeling ${widget.capsule.mood}',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _reveal,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Break the seal ✨',
                            style: TextStyle(
                              color: Color(0xFF1A1500),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    FadeTransition(
                      opacity: _contentFade,
                      child: Column(
                        children: [
                          if (widget.capsule.mood != null)
                            Text(
                              widget.capsule.mood!,
                              style: const TextStyle(fontSize: 36),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            widget.capsule.message,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontSize: 17,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '— You, ${_formatDate(widget.capsule.createdAt)}',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(true),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.purple
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                    color: AppColors.purpleSoft,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
