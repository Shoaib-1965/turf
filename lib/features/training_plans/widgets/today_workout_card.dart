import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/training_plan.dart';

/// Prominent card showing today's workout details and start button.
class TodayWorkoutCard extends StatelessWidget {
  final DayWorkout workout;
  final VoidCallback onStartTap;

  const TodayWorkoutCard({
    super.key,
    required this.workout,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TODAY'S WORKOUT label ──────────────
            Text(
              "TODAY'S WORKOUT",
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(height: 8),

            // ── Workout name ──────────────────────
            Text(
              workout.name,
              style: GoogleFonts.bebasNeue(
                fontSize: 32,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            // ── Tag chips ─────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _tagChip(_effortLabel),
                if (workout.distanceKm > 0)
                  _tagChip('${workout.distanceKm} km'),
                _tagChip('Aerobic'),
              ],
            ),

            if (workout.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                workout.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Metrics row ───────────────────────
            IntrinsicHeight(
              child: Row(
                children: [
                  _metric(
                    '${workout.distanceKm} km',
                    'Distance',
                  ),
                  _divider(),
                  _metric(
                    '${workout.targetPace}/km',
                    'Target Pace',
                  ),
                  _divider(),
                  _metric(
                    '~${workout.estMinutes} min',
                    'Est. Duration',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Start button ──────────────────────
            GestureDetector(
              onTap: onStartTap,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'START THIS WORKOUT →',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _effortLabel => switch (workout.effort) {
        Effort.easy => 'Easy',
        Effort.moderate => 'Moderate',
        Effort.hard => 'Hard',
      };

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightTeal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFE0F2F1),
    );
  }
}
