import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_button.dart';
import '../models/models.dart';
import '../providers/user_profile_provider.dart';

class ArchetypeScreen extends StatefulWidget {
  const ArchetypeScreen({super.key});

  @override
  State<ArchetypeScreen> createState() => _ArchetypeScreenState();
}

class _ArchetypeScreenState extends State<ArchetypeScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      const Text(
                        'Step 1 of 3',
                        style: TextStyle(color: AppColors.grey, fontSize: 13),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/welcome'),
                        child: const Icon(Icons.arrow_back_ios,
                            color: AppColors.grey, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.33,
                      backgroundColor: AppColors.card,
                      valueColor: AlwaysStoppedAnimation(AppColors.purple),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Choose your\nversion',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Who do you aspire to become?',
                    style: TextStyle(color: AppColors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: AppData.archetypes.length,
                itemBuilder: (_, i) {
                  final a = AppData.archetypes[i];
                  final selected = _selectedId == a.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedId = a.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.purple.withValues(alpha: 0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              selected ? AppColors.purple : AppColors.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.emoji, style: const TextStyle(fontSize: 32)),
                          const Spacer(),
                          Text(
                            a.title,
                            style: TextStyle(
                              color:
                                  selected ? AppColors.purple : AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.tagline,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.purple,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Selected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: OnoButton(
                label: 'Continue',
                onPressed: _selectedId == null
                    ? null
                    : () {
                        context
                            .read<UserProfileProvider>()
                            .selectArchetype(_selectedId!);
                        context.go('/assessment/$_selectedId');
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
