import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../models/leaderboard_entry.dart';

/// A single leaderboard row for rank 4+.
class LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF00897B).withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMe
                    ? AppColors.primaryTeal.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.75),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // ── Left accent bar (current user only) ────
                if (isMe)
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                // ── Rank number ────────────────────────────
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Text(
                        '${entry.rank}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _RankChangeIndicator(change: entry.rankChange),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── Avatar ────────────────────────────────
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.backgroundAlt,
                  backgroundImage: NetworkImage(entry.photoUrl),
                ),

                const SizedBox(width: 12),

                // ── Name + runs ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.username,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            _youChip(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.runsThisWeek} runs this week',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Territory km² ─────────────────────────
                Text(
                  '${entry.territoryKm2} km²',
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _youChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'YOU',
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _RankChangeIndicator extends StatelessWidget {
  final int change;

  const _RankChangeIndicator({required this.change});

  @override
  Widget build(BuildContext context) {
    if (change > 0) {
      return Text(
        '↑$change',
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.successGreen,
        ),
      );
    } else if (change < 0) {
      return Text(
        '↓${change.abs()}',
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.errorRed,
        ),
      );
    } else {
      return Text(
        '—',
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          color: AppColors.textTertiary,
        ),
      );
    }
  }
}
