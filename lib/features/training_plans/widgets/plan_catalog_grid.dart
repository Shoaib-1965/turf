import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/training_plan.dart';

/// 2-column grid of available training plans.
class PlanCatalogGrid extends StatelessWidget {
  final List<PlanCatalogItem> plans;

  const PlanCatalogGrid({super.key, required this.plans});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: plans.map((p) => _CatalogCard(plan: p)).toList(),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final PlanCatalogItem plan;

  const _CatalogCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;

    return SizedBox(
      width: cardWidth,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target badge chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plan.targetLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Plan name
            Text(
              plan.name,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Weeks + difficulty
            Row(
              children: [
                Text(
                  '${plan.weeks} weeks',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _difficultyColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  plan.difficulty,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Start plan link
            Text(
              'Start Plan',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _difficultyColor {
    if (plan.difficulty == 'Beginner') return AppColors.successGreen;
    if (plan.difficulty == 'Intermediate') return AppColors.warningOrange;
    return AppColors.errorRed;
  }
}
