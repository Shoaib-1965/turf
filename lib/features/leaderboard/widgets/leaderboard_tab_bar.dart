import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../providers/leaderboard_provider.dart';

/// Glass pill tab bar for Global / Local / Friends.
class LeaderboardTabBar extends StatelessWidget {
  final LeaderboardTab selected;
  final ValueChanged<LeaderboardTab> onSelected;

  const LeaderboardTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _labels = {
    LeaderboardTab.global: 'Global',
    LeaderboardTab.local: 'Local',
    LeaderboardTab.friends: 'Friends',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 3;
                return Stack(
                  children: [
                    // ── Sliding active indicator ──────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      left: selected.index * tabWidth,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primaryTeal.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Tab labels ───────────────────────
                    Row(
                      children: LeaderboardTab.values.map((tab) {
                        final isActive = tab == selected;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onSelected(tab),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                child: Text(_labels[tab]!),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
