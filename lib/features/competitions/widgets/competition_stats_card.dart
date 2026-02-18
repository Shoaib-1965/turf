import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

/// 2×2 grid of competition stats.
class CompetitionStatsCard extends StatelessWidget {
  const CompetitionStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MY STATS',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stat('Total Entered', '4', false),
                const SizedBox(width: 14),
                _stat('Total Entries', '63', false),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stat('Competitions Won', '0', true),
                const SizedBox(width: 14),
                _stat('Best Finish', 'Top 8%', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, bool isTeal) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isTeal ? AppColors.primaryTeal : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
