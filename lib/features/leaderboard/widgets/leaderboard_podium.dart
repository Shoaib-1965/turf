import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/leaderboard_entry.dart';

/// Podium showing the top 3 runners in [2nd] [1st] [3rd] layout.
class LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardEntry> top3;

  const LeaderboardPodium({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    if (top3.length < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                AppColors.primaryTeal.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── 2nd Place ─────────────────────────
              Expanded(
                child: _PodiumSlot(
                  entry: top3[1],
                  avatarSize: 60,
                  borderWidth: 2.5,
                  borderColor: AppColors.silverAccent,
                  medal: '🥈',
                  columnHeight: 100,
                  animDelay: 150,
                ),
              ),
              const SizedBox(width: 8),
              // ── 1st Place ─────────────────────────
              Expanded(
                child: _PodiumSlot(
                  entry: top3[0],
                  avatarSize: 72,
                  borderWidth: 3,
                  borderColor: AppColors.goldAccent,
                  medal: '🥇',
                  columnHeight: 130,
                  isFirst: true,
                  animDelay: 0,
                ),
              ),
              const SizedBox(width: 8),
              // ── 3rd Place ─────────────────────────
              Expanded(
                child: _PodiumSlot(
                  entry: top3[2],
                  avatarSize: 56,
                  borderWidth: 2.5,
                  borderColor: AppColors.bronzeAccent,
                  medal: '🥉',
                  columnHeight: 80,
                  animDelay: 300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final double avatarSize;
  final double borderWidth;
  final Color borderColor;
  final String medal;
  final double columnHeight;
  final bool isFirst;
  final int animDelay;

  const _PodiumSlot({
    required this.entry,
    required this.avatarSize,
    required this.borderWidth,
    required this.borderColor,
    required this.medal,
    required this.columnHeight,
    this.isFirst = false,
    this.animDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: columnHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Avatar ───────────────────────────────
          Container(
            decoration: isFirst
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : null,
            child: CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: borderColor,
              child: CircleAvatar(
                radius: (avatarSize / 2) - borderWidth,
                backgroundColor: AppColors.backgroundAlt,
                backgroundImage: NetworkImage(entry.photoUrl),
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                delay: Duration(milliseconds: animDelay),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 6),

          // ── Medal ────────────────────────────────
          Text(medal, style: const TextStyle(fontSize: 18)),

          const SizedBox(height: 2),

          // ── Username ─────────────────────────────
          Text(
            entry.username,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // ── Territory ────────────────────────────
          Text(
            '${entry.territoryKm2} km²',
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}
