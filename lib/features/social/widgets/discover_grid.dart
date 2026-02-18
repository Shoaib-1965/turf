import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/social_post.dart';

/// 2-column grid of suggested users to follow.
class DiscoverGrid extends StatelessWidget {
  final List<SuggestedUser> users;

  const DiscoverGrid({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: users.map((u) => _UserCard(user: u)).toList(),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final SuggestedUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;

    return SizedBox(
      width: cardWidth,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.backgroundAlt,
              backgroundImage: NetworkImage(user.photoUrl),
            ),
            const SizedBox(height: 10),
            Text(
              user.username,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${user.territoryKm2} km²',
              style: GoogleFonts.robotoMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${user.mutualFriends} mutual friends',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Follow',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
