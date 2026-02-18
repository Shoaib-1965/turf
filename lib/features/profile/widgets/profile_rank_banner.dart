import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

/// Gold rank banner showing global rank, percentile and progress bar.
class ProfileRankBanner extends StatelessWidget {
  final int globalRank;
  final double percentile; // 0.0–1.0

  const ProfileRankBanner({
    super.key,
    required this.globalRank,
    required this.percentile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Crown icon ──────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // ── Rank text ───────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global Rank #$globalRank',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      color: const Color(0xFFF9A825),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Top ${((1 - percentile) * 100).round()}% this month',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Progress bar ──────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentile,
                      minHeight: 5,
                      backgroundColor: AppColors.lightTeal,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
