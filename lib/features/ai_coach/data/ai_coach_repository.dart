import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:turf_app/features/ai_coach/domain/models/chat_message.dart';
import 'package:turf_app/features/ai_coach/domain/models/coach_context.dart';

/// Repository that handles AI Coach interactions and Supabase persistence.
class AiCoachRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get isApiAvailable {
    final key = dotenv.env['FIREWORKS_API_KEY'];
    return key != null && key.isNotEmpty && key != 'your_actual_api_key_goes_here';
  }

  /// Fetches historical chat messages from Supabase
  Future<List<ChatMessage>> getChatHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _supabase
          .from('ai_chat_messages')
          .select()
          .order('created_at', ascending: true);

      return (data as List).map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
    }
  }

  /// Saves a single chat message to Supabase
  Future<void> saveMessage(ChatMessage message) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('ai_chat_messages').insert(message.toJson(userId));
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  /// Sends the conversation history and returns an AI response.
  Future<ChatMessage> getCoachResponse(
    List<ChatMessage> conversationHistory,
  ) async {
    // Determine the last user message
    final lastUserMessage = conversationHistory.lastWhere((m) => m.isUser).content;
    
    ChatMessage assistantMessage;

    if (isApiAvailable) {
      // TODO: Implement actual Fireworks API call here using http package
      // For now, even if API is "available", we fall back to stub if not fully implemented
      assistantMessage = await _getStubResponse(lastUserMessage);
    } else {
      assistantMessage = await _getStubResponse(lastUserMessage);
    }

    // Persist the assistant message
    await saveMessage(assistantMessage);

    return assistantMessage;
  }

  /// Sends live activity context and returns a proactive coaching tip.
  Future<ChatMessage> getLiveCoachingTip(CoachContext context) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Stubbed logic
    String tip;
    if (context.currentSpeedKmh != null && context.currentSpeedKmh! > 0 && context.currentSpeedKmh! < 6) {
      tip = '🏃 You\'re at a comfortable jogging pace. Try to maintain a steady cadence for the next kilometre – consistency beats bursts!';
    } else if (context.currentSpeedKmh != null && context.currentSpeedKmh! >= 6 && context.currentSpeedKmh! < 12) {
      tip = '⚡ Great pace! You\'re covering ground quickly. Keep your breathing rhythmic – in for 3 steps, out for 2.';
    } else if (context.currentDistanceKm != null && context.currentDistanceKm! > 3) {
      tip = '💧 You\'ve passed 3 km – consider a quick hydration break if you haven\'t already. Staying hydrated prevents late-run fatigue.';
    } else {
      tip = '💪 Keep going! Focus on your form – shoulders relaxed, arms at 90°, and land mid-foot.';
    }

    final message = ChatMessage.assistant(tip);
    
    // Add metadata so we know it's a live coaching tip
    final messageWithMeta = message.copyWith(metadata: {'isLiveCoaching': true});
    
    // Persist the live tip
    await saveMessage(messageWithMeta);

    return messageWithMeta;
  }

  Future<ChatMessage> _getStubResponse(String input) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 1200));
    final lowerInput = input.toLowerCase();
    
    String response;

    if (lowerInput.contains('pace') || lowerInput.contains('speed')) {
      response = '**Improving Your Pace** 🏃\n\n'
          'Here are a few tips to boost your running pace:\n\n'
          '1. **Interval training** – alternate between fast and recovery jogs\n'
          '2. **Cadence drills** – aim for 170-180 steps per minute\n'
          '3. **Hill repeats** – builds leg strength and power\n'
          '4. **Consistent mileage** – build your base before chasing speed\n\n'
          'Would you like me to create a personalized interval plan?';
    } else if (lowerInput.contains('nutrition') || lowerInput.contains('diet') || lowerInput.contains('food')) {
      response = '**Nutrition for Runners** 🥗\n\n'
          'Key fueling guidelines:\n\n'
          '• **Pre-run (1-2 hrs before):** Light carbs – banana, toast, oatmeal\n'
          '• **During (60+ min runs):** Energy gels or sports drink\n'
          '• **Post-run (within 30 min):** Protein + carbs – chocolate milk, rice & chicken\n\n'
          'Stay hydrated! Aim for at least 2-3 litres of water daily.';
    } else if (lowerInput.contains('leaderboard') || lowerInput.contains('rank')) {
      response = '**Leaderboard Strategy** 🏆\n\n'
          'To climb the rankings:\n\n'
          '1. **Consistency wins** – log activities daily\n'
          '2. **Capture territories** – they give bonus XP\n'
          '3. **Join challenges** – weekly challenges have rank multipliers\n'
          '4. **Streak bonus** – maintain your daily streak for XP boosts';
    } else if (lowerInput.contains('workout') || lowerInput.contains('plan') || lowerInput.contains('training')) {
      response = '**Today\'s Workout Plan** 💪\n\n'
          '**Warm-up (5 min):** Light jog + dynamic stretches\n\n'
          '**Main set:**\n'
          '• 4 × 400m at tempo pace (90 sec rest)\n'
          '• 2 × 800m at threshold pace (2 min rest)\n'
          '• 4 × 200m sprints (60 sec rest)\n\n'
          '**Cool-down (5 min):** Easy jog + static stretches\n\n'
          'Total estimated time: ~45 minutes';
    } else if (lowerInput.contains('territory') || lowerInput.contains('capture') || lowerInput.contains('strategy')) {
      response = '**Territory Strategy** 🗺️\n\n'
          'Smart territory tips:\n\n'
          '1. **Plan your route** – target unclaimed zones first\n'
          '2. **Off-peak hours** – capture during quiet times to avoid competition\n'
          '3. **Loop routes** – maximize territory coverage in a single run\n'
          '4. **Defend your turf** – revisit captured zones weekly to maintain control';
    } else if (lowerInput.contains('stats') || lowerInput.contains('weekly') || lowerInput.contains('progress')) {
      response = '**Weekly Stats Overview** 📊\n\n'
          'I\'d need access to your latest activity data to give exact numbers. '
          'In the meantime, here\'s what to focus on:\n\n'
          '• Compare this week\'s distance to last week\n'
          '• Track your average pace trend\n'
          '• Check your elevation gain progress\n\n'
          'Head to your **Profile → Stats** tab for detailed analytics!';
    } else if (lowerInput.contains('recovery') || lowerInput.contains('rest') || lowerInput.contains('sleep')) {
      response = '**Recovery Advice** 😴\n\n'
          'Proper recovery is just as important as training:\n\n'
          '• **Sleep 7-9 hours** – growth hormone peaks during deep sleep\n'
          '• **Active recovery** – light walks or yoga on rest days\n'
          '• **Foam rolling** – targets tight spots and improves circulation\n'
          '• **Protein intake** – 1.2-1.6g per kg of body weight daily\n'
          '• **Listen to your body** – persistent soreness means more rest';
    } else if (lowerInput.contains('calorie') || lowerInput.contains('burn') || lowerInput.contains('weight')) {
      response = '**Calorie Tracking Tips** 🔥\n\n'
          'For accurate calorie management:\n\n'
          '1. **Log consistently** – track every meal and snack\n'
          '2. **Running burns ~60-100 cal/km** depending on weight and pace\n'
          '3. **Don\'t over-compensate** – avoid eating back all exercise calories\n'
          '4. **Balanced macros** – 50% carbs, 25% protein, 25% fats for runners\n\n'
          'Your TURF activity tracking already estimates your burn per session!';
    } else {
      response = 'That\'s a great question! 🤔\n\n'
          'I can help you with:\n'
          '• **Running tips** – pace, form, training plans\n'
          '• **Nutrition** – fueling strategies\n'
          '• **Territory strategy** – capturing and defending zones\n'
          '• **Recovery** – rest and injury prevention\n'
          '• **Stats** – understanding your progress\n\n'
          'What would you like to explore?';
    }

    return ChatMessage.assistant(response);
  }
}
