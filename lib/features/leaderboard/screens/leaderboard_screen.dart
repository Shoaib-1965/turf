import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.leaderboard_rounded,
                size: 48,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(height: 12),
              Text('Leaderboard', style: AppTypography.headlineLarge),
              const SizedBox(height: 4),
              Text('Rankings coming soon', style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
