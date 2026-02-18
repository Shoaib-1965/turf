import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/user_profile_provider.dart';

/// Horizontal scroll of achievement badges (earned + locked).
class ProfileAchievements extends StatelessWidget {
  final List<String> earnedIds;

  const ProfileAchievements({super.key, required this.earnedIds});

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
              'ACHIEVEMENTS',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allAchievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final badge = allAchievements[i];
                  final isEarned = earnedIds.contains(badge.id);
                  return _BadgeCard(badge: badge, isEarned: isEarned);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementDef badge;
  final bool isEarned;

  const _BadgeCard({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isEarned
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEarned
              ? Colors.white.withValues(alpha: 0.75)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 38,
                  color: isEarned
                      ? null
                      : AppColors.textTertiary.withValues(alpha: 0.40),
                ),
              ),
              if (!isEarned)
                Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: AppColors.textTertiary.withValues(alpha: 0.60),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: isEarned ? FontWeight.w700 : FontWeight.w500,
              color: isEarned ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
