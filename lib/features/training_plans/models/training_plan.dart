/// Training plan goal types.
enum TrainingGoal { fiveK, tenK, halfMarathon, marathon, justRun }

/// Workout effort level.
enum Effort { easy, moderate, hard }

/// Status of a single day's workout.
enum DayStatus { completed, today, upcoming, rest, missed }

/// A single day's workout in the training plan.
class DayWorkout {
  final int dayIndex; // 0 = Mon … 6 = Sun
  final String dayLabel;
  final String name;
  final String shortLabel;
  final String emoji;
  final DayStatus status;
  final Effort effort;
  final double distanceKm;
  final String targetPace;
  final int estMinutes;
  final String description;

  const DayWorkout({
    required this.dayIndex,
    required this.dayLabel,
    required this.name,
    required this.shortLabel,
    this.emoji = '🏃',
    this.status = DayStatus.upcoming,
    this.effort = Effort.easy,
    this.distanceKm = 0,
    this.targetPace = '',
    this.estMinutes = 0,
    this.description = '',
  });
}

/// One week of training.
class TrainingWeek {
  final int weekNumber;
  final List<DayWorkout> days;

  const TrainingWeek({required this.weekNumber, required this.days});
}

/// A complete training plan.
class TrainingPlan {
  final String id;
  final String name;
  final TrainingGoal goal;
  final int totalWeeks;
  final int currentWeek;
  final int completedThisWeek;
  final String difficulty;
  final TrainingWeek currentWeekSchedule;
  final List<DayWorkout> upcoming;

  const TrainingPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.totalWeeks,
    this.currentWeek = 1,
    this.completedThisWeek = 0,
    this.difficulty = 'Beginner',
    required this.currentWeekSchedule,
    this.upcoming = const [],
  });

  double get weekProgress => totalWeeks > 0 ? currentWeek / totalWeeks : 0;
}

/// A plan available in the catalog.
class PlanCatalogItem {
  final String id;
  final String name;
  final TrainingGoal goal;
  final String targetLabel;
  final int weeks;
  final String difficulty;

  const PlanCatalogItem({
    required this.id,
    required this.name,
    required this.goal,
    required this.targetLabel,
    required this.weeks,
    required this.difficulty,
  });
}
