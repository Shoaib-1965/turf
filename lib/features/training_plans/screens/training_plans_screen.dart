import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../models/training_plan.dart';
import '../providers/training_plan_provider.dart';
import '../widgets/active_plan_banner.dart';
import '../widgets/plan_catalog_grid.dart';
import '../widgets/today_workout_card.dart';
import '../widgets/training_goal_chips.dart';
import '../widgets/upcoming_workouts_list.dart';
import '../widgets/week_schedule_row.dart';

class TrainingPlansScreen extends ConsumerWidget {
  const TrainingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = ref.watch(selectedGoalProvider);
    final asyncPlan = ref.watch(trainingPlanProvider(selectedGoal));
    final catalog = ref.watch(planCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(title: 'TRAINING'),
      body: asyncPlan.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load plan',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (plan) => _buildBody(context, ref, plan, catalog),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TrainingPlan plan,
    List<PlanCatalogItem> catalog,
  ) {
    // Find today's workout
    final todayWorkout = plan.currentWeekSchedule.days
        .where((d) => d.status == DayStatus.today)
        .toList();

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 120,
      ),
      children: [
        const SizedBox(height: 12),

        // ── 1. Goal chips ─────────────────────────
        TrainingGoalChips(
          selected: ref.watch(selectedGoalProvider),
          onChanged: (g) => ref.read(selectedGoalProvider.notifier).state = g,
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // ── 2. Active plan banner ─────────────────
        ActivePlanBanner(plan: plan)
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 18),

        // ── 3. This week header ───────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'THIS WEEK',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 10),

        WeekScheduleRow(week: plan.currentWeekSchedule)
            .animate()
            .fadeIn(delay: 250.ms, duration: 400.ms)
            .slideX(begin: 0.1, end: 0, delay: 250.ms, duration: 400.ms),

        const SizedBox(height: 18),

        // ── 4. Today's workout ────────────────────
        if (todayWorkout.isNotEmpty)
          TodayWorkoutCard(
            workout: todayWorkout.first,
            onStartTap: () => context.go('/run/active'),
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms)
              .slideY(begin: 0.08, end: 0, delay: 350.ms, duration: 400.ms),

        const SizedBox(height: 18),

        // ── 5. Upcoming ───────────────────────────
        if (plan.upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'UPCOMING',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
          const SizedBox(height: 10),
          UpcomingWorkoutsList(workouts: plan.upcoming)
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(begin: 0.08, end: 0, delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 18),
        ],

        // ── 6. Plan catalog ───────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'BROWSE ALL PLANS',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

        const SizedBox(height: 10),

        PlanCatalogGrid(plans: catalog)
            .animate()
            .fadeIn(delay: 650.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0, delay: 650.ms, duration: 400.ms),

        const SizedBox(height: 20),
      ],
    );
  }
}
