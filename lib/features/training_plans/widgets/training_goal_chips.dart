import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../models/training_plan.dart';

/// Horizontal filter chips for training goals.
class TrainingGoalChips extends StatelessWidget {
  final TrainingGoal selected;
  final ValueChanged<TrainingGoal> onChanged;

  const TrainingGoalChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _labels = {
    TrainingGoal.fiveK: '5K',
    TrainingGoal.tenK: '10K',
    TrainingGoal.halfMarathon: 'Half Marathon',
    TrainingGoal.marathon: 'Marathon',
    TrainingGoal.justRun: 'Just Run',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: TrainingGoal.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final goal = TrainingGoal.values[i];
          final isActive = goal == selected;
          return GestureDetector(
            onTap: () => onChanged(goal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                _labels[goal]!,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
