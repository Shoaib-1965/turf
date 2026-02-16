import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class RunSummaryScreen extends StatelessWidget {
  final String runId;

  const RunSummaryScreen({super.key, required this.runId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(title: 'Run Summary'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: AppColors.accentTeal,
            ),
            const SizedBox(height: 16),
            Text('Run Summary', style: AppTypography.headlineLarge),
            const SizedBox(height: 4),
            Text('Run ID: $runId', style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
