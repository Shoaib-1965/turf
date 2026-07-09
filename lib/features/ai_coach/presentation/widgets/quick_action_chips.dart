import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class QuickActionChips extends StatelessWidget {
  final void Function(String text) onChipTapped;
  final bool compact;

  const QuickActionChips({
    super.key,
    required this.onChipTapped,
    this.compact = false,
  });

  static const List<_ChipData> _chips = [
    _ChipData('🏃 Pacing tips', 'Give me pacing tips for my run'),
    _ChipData('🔥 Warm-up routine', 'What is a good warm-up routine?'),
    _ChipData('💤 Recovery advice', 'How should I recover after a workout?'),
    _ChipData('🥗 Nutrition guide', 'What should I eat before and after running?'),
    _ChipData('🌟 Beginner plan', 'I\'m a beginner, how do I start running?'),
    _ChipData('🗺️ Territory strategy', 'How do I claim territory effectively in TURF?'),
  ];

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactChips();
    }
    return _buildFullChips();
  }

  Widget _buildFullChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _chips.map((chip) {
          return GestureDetector(
            onTap: () => onChipTapped(chip.prompt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 1,
                ),
              ),
              child: Text(
                chip.label,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _chips[index];
          return GestureDetector(
            onTap: () => onChipTapped(chip.prompt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 0.5,
                ),
              ),
              child: Text(
                chip.label,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipData {
  final String label;
  final String prompt;

  const _ChipData(this.label, this.prompt);
}
