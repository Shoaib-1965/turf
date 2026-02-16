import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

/// 2×3 grid of stat cells with dividers.
class StatsGridCard extends StatelessWidget {
  final String distance;
  final String duration;
  final String avgPace;
  final String bestPace;
  final String territory;
  final String calories;

  const StatsGridCard({
    super.key,
    required this.distance,
    required this.duration,
    required this.avgPace,
    required this.bestPace,
    required this.territory,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.80),
            ),
          ),
          child: Column(
            children: [
              _buildRow([
                _StatCell(label: 'DISTANCE', value: distance, unit: 'km'),
                _StatCell(label: 'DURATION', value: duration),
              ]),
              _divider(),
              _buildRow([
                _StatCell(label: 'AVG PACE', value: avgPace, unit: '/km'),
                _StatCell(label: 'BEST PACE', value: bestPace, unit: '/km'),
              ]),
              _divider(),
              _buildRow([
                _StatCell(
                  label: 'TERRITORY',
                  value: territory,
                  unit: 'km²',
                  valueColor: AppColors.primaryTeal,
                ),
                _StatCell(label: 'CALORIES', value: calories, unit: 'kcal'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<_StatCell> cells) {
    return IntrinsicHeight(
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++) ...[
            if (i > 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: const Color(0xFFE0F2F1),
              ),
            Expanded(child: cells[i]),
          ],
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: const Color(0xFFE0F2F1)),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(
                unit!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
