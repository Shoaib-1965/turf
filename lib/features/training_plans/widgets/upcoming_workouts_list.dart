import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/training_plan.dart';

/// Compact list of upcoming workouts with effort dots.
class UpcomingWorkoutsList extends StatelessWidget {
  final List<DayWorkout> workouts;

  const UpcomingWorkoutsList({super.key, required this.workouts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: workouts
            .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _UpcomingTile(workout: w),
                ))
            .toList(),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final DayWorkout workout;

  const _UpcomingTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 14,
      fillOpacity: 0.50,
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 44,
            child: Text(
              workout.dayLabel,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Workout name + distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (workout.distanceKm > 0)
                  Text(
                    '${workout.distanceKm} km',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Effort dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _effortColor,
            ),
          ),
        ],
      ),
    );
  }

  Color get _effortColor => switch (workout.effort) {
        Effort.easy => AppColors.successGreen,
        Effort.moderate => AppColors.warningOrange,
        Effort.hard => AppColors.errorRed,
      };
}
