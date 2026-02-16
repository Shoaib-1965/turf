import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

/// Top glass pill bar with PAUSE / duration / STOP controls.
class RunControlBar extends StatelessWidget {
  final String duration;
  final bool isPaused;
  final VoidCallback onPauseTap;
  final VoidCallback onStopTap;

  const RunControlBar({
    super.key,
    required this.duration,
    required this.isPaused,
    required this.onPauseTap,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.80),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Pause / Resume ─────────────────────────
              GestureDetector(
                onTap: onPauseTap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPaused
                        ? AppColors.primaryTeal.withValues(alpha: 0.10)
                        : Colors.grey.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: isPaused
                        ? AppColors.primaryTeal
                        : AppColors.textSecondary,
                    size: 26,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // ── Duration stopwatch ─────────────────────
              Text(
                duration,
                style: GoogleFonts.robotoMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(width: 20),

              // ── Stop ───────────────────────────────────
              GestureDetector(
                onTap: onStopTap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.errorRed.withValues(alpha: 0.10),
                  ),
                  child: const Icon(
                    Icons.stop_circle_rounded,
                    color: AppColors.errorRed,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
