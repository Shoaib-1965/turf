import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../providers/leaderboard_provider.dart';

/// Horizontal scroll of glass filter chips (This Month / This Week / All Time).
class LeaderboardFilterChips extends StatelessWidget {
  final LeaderboardPeriod selected;
  final ValueChanged<LeaderboardPeriod> onSelected;

  const LeaderboardFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _labels = {
    LeaderboardPeriod.thisMonth: 'This Month',
    LeaderboardPeriod.thisWeek: 'This Week',
    LeaderboardPeriod.allTime: 'All Time',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: LeaderboardPeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final period = LeaderboardPeriod.values[index];
          final isActive = period == selected;
          return GestureDetector(
            onTap: () => onSelected(period),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryTeal
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryTeal
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Text(
                    _labels[period]!,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
