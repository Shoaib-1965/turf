import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

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
                Icons.person_rounded,
                size: 48,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(height: 12),
              Text('Profile', style: AppTypography.headlineLarge),
              const SizedBox(height: 4),
              Text(
                userId != null ? 'User: $userId' : 'Your profile',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
