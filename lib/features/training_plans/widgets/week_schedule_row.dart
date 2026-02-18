import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../models/training_plan.dart';

/// Horizontal scroll of 7 day cards showing the current week's schedule.
class WeekScheduleRow extends StatelessWidget {
  final TrainingWeek week;

  const WeekScheduleRow({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: week.days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _DayCard(day: week.days[i]),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DayWorkout day;

  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: day.status == DayStatus.today
              ? AppColors.primaryTeal.withValues(alpha: 0.50)
              : Colors.white.withValues(alpha: 0.75),
          width: day.status == DayStatus.today ? 2 : 1,
        ),
        boxShadow: day.status == DayStatus.today
            ? [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day label
          Text(
            day.dayLabel,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 6),

          // Emoji or status icon
          _statusIcon,

          const SizedBox(height: 6),

          // Short workout label
          Text(
            day.shortLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          // TODAY label
          if (day.status == DayStatus.today)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'TODAY',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color get _bgColor => switch (day.status) {
        DayStatus.completed => AppColors.primaryTeal.withValues(alpha: 0.08),
        DayStatus.today => Colors.white.withValues(alpha: 0.75),
        DayStatus.rest => Colors.grey.withValues(alpha: 0.08),
        DayStatus.missed => AppColors.errorRed.withValues(alpha: 0.06),
        DayStatus.upcoming => Colors.white.withValues(alpha: 0.55),
      };

  Widget get _statusIcon {
    if (day.status == DayStatus.completed) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Text(day.emoji, style: const TextStyle(fontSize: 24)),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.successGreen),
          ),
        ],
      );
    }
    if (day.status == DayStatus.missed) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Text(day.emoji, style: const TextStyle(fontSize: 24)),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.warning_rounded,
                size: 14, color: AppColors.errorRed),
          ),
        ],
      );
    }
    return Text(day.emoji, style: const TextStyle(fontSize: 24));
  }
}
