import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class EnergySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const EnergySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Color _trackColor() {
    if (value < 0.25) return const Color(0xFFEF4444);
    if (value < 0.5) return AppColors.warning;
    if (value < 0.75) return AppColors.green;
    return AppColors.cyan;
  }

  String _energyLabel() {
    if (value < 0.2) return 'Drained';
    if (value < 0.4) return 'Low';
    if (value < 0.6) return 'Moderate';
    if (value < 0.8) return 'Good';
    return 'Energized';
  }

  @override
  Widget build(BuildContext context) {
    final color = _trackColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Energy Level',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                _energyLabel(),
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // Custom gradient track
              SizedBox(
                height: 48,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Background track
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEF4444),
                                Color(0xFFF59E0B),
                                Color(0xFF34D399),
                                Color(0xFF22D3EE),
                              ],
                            ),
                          ),
                        ),
                        // Active fill
                        Container(
                          width: constraints.maxWidth * value,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFEF4444),
                                color,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        // Slider (invisible, on top)
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 8,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                              elevation: 4,
                            ),
                            overlayColor: color.withValues(alpha: 0.2),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 24,
                            ),
                          ),
                          child: Slider(
                            value: value,
                            onChanged: onChanged,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Drained',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Energized',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
