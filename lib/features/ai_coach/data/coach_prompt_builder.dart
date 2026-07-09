import 'package:turf_app/features/ai_coach/domain/models/coach_context.dart';

/// Builds system and coaching prompts for the TURF AI Coach.
class CoachPromptBuilder {
  CoachPromptBuilder._();

  /// Builds the system prompt that trains the model as TURF's fitness coach.
  static String buildSystemPrompt(CoachContext context) {
    final contextData = context.toContextString();

    return '''You are TURF Coach — an AI fitness coach built into the TURF territory capture fitness app.

Your role is to help users improve their fitness, optimize their running/cycling/walking performance, and strategize their territory capture gameplay.

CORE RULES:
- Be motivational but concise — users read on mobile screens.
- Keep responses under 150 words unless the user explicitly asks for more detail.
- Use emojis sparingly (1-2 per response) for engagement.
- Never make medical diagnoses. Always recommend consulting a healthcare professional for medical concerns.
- Be knowledgeable about running pace, cycling cadence, walking form, nutrition, hydration, recovery, and sleep.
- Understand TURF's territory capture mechanics — users claim land by exercising outdoors.
- If live activity data is present, prioritize real-time coaching over general advice.
- Reference the user's actual stats when giving advice to make it personal.
- Celebrate milestones and streaks to keep motivation high.

USER CONTEXT:
$contextData''';
  }

  /// Builds a specific prompt for live activity coaching.
  ///
  /// Returns a focused prompt that includes current metrics and asks for
  /// a brief 1-2 sentence coaching tip based on the live data.
  static String buildLiveCoachingPrompt(CoachContext context) {
    if (!context.isInLiveActivity) {
      return 'The user is not currently in a live activity. Offer a general motivation tip or suggest starting an activity.';
    }

    final buffer = StringBuffer();
    buffer.writeln(
        'The user is currently in a LIVE ${context.currentActivityType} session. Provide a brief (1-2 sentence) coaching tip based on these real-time metrics:');
    buffer.writeln();

    if (context.currentSpeedKmh != null) {
      buffer.writeln(
          '• Current Speed: ${context.currentSpeedKmh!.toStringAsFixed(1)} km/h');
    }
    if (context.currentPaceMinPerKm != null) {
      buffer.writeln(
          '• Current Pace: ${context.currentPaceMinPerKm!.toStringAsFixed(2)} min/km');
    }
    if (context.currentDistanceKm != null) {
      buffer.writeln(
          '• Distance So Far: ${context.currentDistanceKm!.toStringAsFixed(2)} km');
    }
    if (context.currentDurationSeconds != null) {
      final minutes = context.currentDurationSeconds! ~/ 60;
      final seconds = context.currentDurationSeconds! % 60;
      buffer.writeln('• Duration: ${minutes}m ${seconds}s');
    }
    if (context.currentCaloriesBurned != null) {
      buffer.writeln('• Calories Burned: ${context.currentCaloriesBurned}');
    }
    if (context.currentElevationGainM != null) {
      buffer.writeln(
          '• Elevation Gain: ${context.currentElevationGainM!.toStringAsFixed(1)} m');
    }
    if (context.landClaimedSqm != null) {
      buffer.writeln(
          '• Territory Claimed: ${context.landClaimedSqm!.toStringAsFixed(0)} sqm');
    }

    buffer.writeln();
    buffer.writeln(
        'Focus on actionable advice for their current performance. Be encouraging and brief.');

    return buffer.toString();
  }
}
