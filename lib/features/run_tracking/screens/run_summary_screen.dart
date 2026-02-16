import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_button.dart';
import '../providers/run_provider.dart';
import '../providers/run_summary_provider.dart';
import '../widgets/achievements_card.dart';
import '../widgets/map_preview_card.dart';
import '../widgets/stats_grid_card.dart';
import '../widgets/territory_breakdown_card.dart';

class RunSummaryScreen extends ConsumerWidget {
  final String runId;

  const RunSummaryScreen({super.key, required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(runSummaryProvider);

    final dateStr = summary.startTime != null
        ? DateFormat('EEEE, MMM d · h:mm a').format(summary.startTime!)
        : 'Just now';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F7),
      body: Column(
        children: [
          // ── App Bar ─────────────────────────────────────
          GlassAppBar(
            title: 'RUN COMPLETE',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.primaryTeal),
              onPressed: () => _backToMap(context, ref),
            ),
          ),

          // ── Scrollable body ─────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                children: [
                  // ── Date / time ───────────────────────────
                  Text(
                    dateStr,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 16),

                  // ── Map preview ───────────────────────────
                  MapPreviewCard(routePoints: summary.routePoints)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 20),

                  // ── Stats grid ────────────────────────────
                  StatsGridCard(
                    distance: summary.distanceKm.toStringAsFixed(1),
                    duration: summary.durationFormatted,
                    avgPace: summary.avgPace,
                    bestPace: summary.bestPace,
                    territory: summary.territoryCapturedKm2.toStringAsFixed(2),
                    calories: summary.calories.toString(),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 20),

                  // ── Territory breakdown ────────────────────
                  TerritoryBreakdownCard(
                    totalCaptured: summary.territoryCapturedKm2,
                    newTerritory: summary.newTerritory,
                    reclaimedTerritory: summary.reclaimedTerritory,
                    competitionPoints: summary.competitionPoints,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 20),

                  // ── Achievements ──────────────────────────
                  AchievementsCard(achievements: summary.achievements)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 28),

                  // ── Action buttons ────────────────────────
                  GlassButton(
                    text: 'SHARE RUN',
                    style: GlassButtonStyle.primary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Share feature coming soon!')),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          text: 'Sync to Strava',
                          style: GlassButtonStyle.secondary,
                          height: 48,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Syncing to Strava...')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          text: 'Save Run',
                          style: GlassButtonStyle.secondary,
                          height: 48,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Run saved locally!')),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => _backToMap(context, ref),
                    child: Text(
                      'Back to Map',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _backToMap(BuildContext context, WidgetRef ref) {
    // Reset run state
    ref.read(runProvider.notifier).stopRun();
    context.goNamed('home');
  }
}
