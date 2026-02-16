import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(title: 'Settings'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_rounded, size: 64, color: AppColors.accentTeal),
            const SizedBox(height: 16),
            Text('Settings', style: AppTypography.headlineLarge),
            const SizedBox(height: 4),
            Text('App settings coming soon', style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
