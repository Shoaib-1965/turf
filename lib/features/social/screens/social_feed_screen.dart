import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

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
                Icons.people_rounded,
                size: 48,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(height: 12),
              Text('Social Feed', style: AppTypography.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Activity feed coming soon',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
