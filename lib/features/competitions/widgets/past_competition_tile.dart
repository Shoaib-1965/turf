import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/competition_model.dart';

/// Compact card for a past competition.
class PastCompetitionTile extends StatelessWidget {
  final PastCompetition competition;

  const PastCompetitionTile({super.key, required this.competition});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        fillOpacity: 0.50,
        blur: 12,
        child: Row(
          children: [
            // ── Prize thumbnail ─────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.backgroundAlt,
                child: Image.network(
                  competition.prizeImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.emoji_events_rounded,
                    size: 28,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Details ─────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    competition.prizeName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Winner row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.backgroundAlt,
                        backgroundImage:
                            NetworkImage(competition.winnerPhotoUrl),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          competition.winnerUsername,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        competition.monthLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'You had ${competition.userEntries} entries',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
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
