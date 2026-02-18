import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/training_plan.dart';

/// Currently selected goal chip.
final selectedGoalProvider =
    StateProvider<TrainingGoal>((ref) => TrainingGoal.tenK);

/// Active training plan based on selected goal.
final trainingPlanProvider =
    FutureProvider.family<TrainingPlan, TrainingGoal>((ref, goal) async {
  await Future.delayed(const Duration(milliseconds: 400));

  final name = switch (goal) {
    TrainingGoal.fiveK => '5K Beginner Plan',
    TrainingGoal.tenK => '10K Beginner Plan',
    TrainingGoal.halfMarathon => 'Half Marathon Builder',
    TrainingGoal.marathon => 'Marathon Training',
    TrainingGoal.justRun => 'Just Run Plan',
  };

  final weeks = switch (goal) {
    TrainingGoal.fiveK => 6,
    TrainingGoal.tenK => 8,
    TrainingGoal.halfMarathon => 12,
    TrainingGoal.marathon => 16,
    TrainingGoal.justRun => 4,
  };

  return TrainingPlan(
    id: 'plan_${goal.name}',
    name: name,
    goal: goal,
    totalWeeks: weeks,
    currentWeek: 3,
    completedThisWeek: 4,
    difficulty: 'Beginner',
    currentWeekSchedule: TrainingWeek(
      weekNumber: 3,
      days: [
        const DayWorkout(
          dayIndex: 0,
          dayLabel: 'MON',
          name: 'Easy 3K Recovery',
          shortLabel: '3K Easy',
          emoji: '🏃',
          status: DayStatus.completed,
          effort: Effort.easy,
          distanceKm: 3.0,
          targetPace: '6:30',
          estMinutes: 20,
        ),
        const DayWorkout(
          dayIndex: 1,
          dayLabel: 'TUE',
          name: 'Tempo Intervals',
          shortLabel: 'Tempo',
          emoji: '💪',
          status: DayStatus.completed,
          effort: Effort.moderate,
          distanceKm: 5.0,
          targetPace: '5:30',
          estMinutes: 28,
        ),
        const DayWorkout(
          dayIndex: 2,
          dayLabel: 'WED',
          name: 'Rest Day',
          shortLabel: 'Rest',
          emoji: '😴',
          status: DayStatus.completed,
          effort: Effort.easy,
        ),
        const DayWorkout(
          dayIndex: 3,
          dayLabel: 'THU',
          name: 'Easy 5K Run',
          shortLabel: '5K Easy',
          emoji: '🏃',
          status: DayStatus.completed,
          effort: Effort.easy,
          distanceKm: 5.0,
          targetPace: '6:00',
          estMinutes: 30,
          description: 'Comfortable pace run focused on building aerobic base. '
              'Keep your heart rate in zone 2 and enjoy the run.',
        ),
        const DayWorkout(
          dayIndex: 4,
          dayLabel: 'FRI',
          name: 'Hill Repeats',
          shortLabel: 'Hills',
          emoji: '💪',
          status: DayStatus.today,
          effort: Effort.hard,
          distanceKm: 4.5,
          targetPace: '5:15',
          estMinutes: 24,
          description:
              'Find a moderate hill. Warm up 1 km, then do 6×200m hill sprints '
              'with jog-back recovery. Cool down 1 km.',
        ),
        const DayWorkout(
          dayIndex: 5,
          dayLabel: 'SAT',
          name: 'Long Slow Run',
          shortLabel: '8K Long',
          emoji: '🏃',
          status: DayStatus.upcoming,
          effort: Effort.moderate,
          distanceKm: 8.0,
          targetPace: '6:15',
          estMinutes: 50,
        ),
        const DayWorkout(
          dayIndex: 6,
          dayLabel: 'SUN',
          name: 'Rest Day',
          shortLabel: 'Rest',
          emoji: '😴',
          status: DayStatus.rest,
          effort: Effort.easy,
        ),
      ],
    ),
    upcoming: [
      const DayWorkout(
        dayIndex: 5,
        dayLabel: 'SAT',
        name: 'Long Slow Run',
        shortLabel: '8K Long',
        emoji: '🏃',
        status: DayStatus.upcoming,
        effort: Effort.moderate,
        distanceKm: 8.0,
        targetPace: '6:15',
        estMinutes: 50,
      ),
      const DayWorkout(
        dayIndex: 0,
        dayLabel: 'MON',
        name: 'Recovery Jog',
        shortLabel: '3K Jog',
        emoji: '🏃',
        status: DayStatus.upcoming,
        effort: Effort.easy,
        distanceKm: 3.0,
        targetPace: '7:00',
        estMinutes: 21,
      ),
      const DayWorkout(
        dayIndex: 1,
        dayLabel: 'TUE',
        name: 'Speed Intervals',
        shortLabel: 'Speed',
        emoji: '💪',
        status: DayStatus.upcoming,
        effort: Effort.hard,
        distanceKm: 6.0,
        targetPace: '5:00',
        estMinutes: 30,
      ),
    ],
  );
});

/// Catalog of available plans.
final planCatalogProvider = Provider<List<PlanCatalogItem>>((ref) => const [
      PlanCatalogItem(
          id: 'cat_5k',
          name: '5K Beginner',
          goal: TrainingGoal.fiveK,
          targetLabel: '5K',
          weeks: 6,
          difficulty: 'Beginner'),
      PlanCatalogItem(
          id: 'cat_10k',
          name: '10K Builder',
          goal: TrainingGoal.tenK,
          targetLabel: '10K',
          weeks: 8,
          difficulty: 'Intermediate'),
      PlanCatalogItem(
          id: 'cat_half',
          name: 'Half Marathon',
          goal: TrainingGoal.halfMarathon,
          targetLabel: '21K',
          weeks: 12,
          difficulty: 'Advanced'),
      PlanCatalogItem(
          id: 'cat_speed',
          name: 'Speed Intervals',
          goal: TrainingGoal.justRun,
          targetLabel: 'Speed',
          weeks: 4,
          difficulty: 'Intermediate'),
    ]);
