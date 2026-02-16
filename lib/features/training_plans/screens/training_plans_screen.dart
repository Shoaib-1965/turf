import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class TrainingPlansScreen extends StatelessWidget {
  const TrainingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(title: 'Training Plans'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 64,
              color: AppColors.accentTeal,
            ),
            const SizedBox(height: 16),
            Text('Training Plans', style: AppTypography.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Workout programs coming soon',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
