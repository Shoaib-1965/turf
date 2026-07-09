import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:turf_app/features/ai_coach/domain/models/chat_message.dart';
import 'package:turf_app/features/ai_coach/domain/models/coach_context.dart';

/// Repository that handles AI Coach interactions, Supabase persistence, and Fireworks API.
class AiCoachRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get isApiAvailable {
    final key = dotenv.env['FIREWORKS_API_KEY'];
    return key != null && key.isNotEmpty && key != 'your_actual_api_key_goes_here';
  }

  static const String _systemPrompt = '''
You are the TURF AI Coach, a highly motivational and knowledgeable athletic companion. 
Your primary goal is to provide concise, actionable, and encouraging advice for running, walking, and cycling.
You specialize in health, nutrition, pacing, speed, recovery, and the TURF leaderboard & territory systems.

Guidelines:
1. Be extremely concise and conversational.
2. Use emojis occasionally for motivation.
3. If the user is currently in a "Live Activity", your response MUST be a short, punchy 1-2 sentence tip that can be read aloud via Text-to-Speech while they run.
4. Base your advice heavily on the provided "User Profile" and "Live Activity" context.
5. If asked about topics outside fitness, nutrition, or the TURF app, politely steer the conversation back to their athletic goals.
''';

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

  Future<String> _callFireworksApi(List<Map<String, String>> messages, {int maxTokens = 250}) async {
    final apiKey = dotenv.env['FIREWORKS_API_KEY'];
    final model = dotenv.env['FIREWORKS_MODEL'] ?? 'accounts/fireworks/models/deepseek-v4-pro';
    final url = dotenv.env['FIREWORKS_BASE_URL'] ?? 'https://api.fireworks.ai/inference/v1';

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    try {
      final response = await http.post(
        Uri.parse('$url/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('API Error: ${response.body}');
        return "I'm having trouble connecting right now. Keep pushing forward!";
      }
    } catch (e) {
      print('Network Error: $e');
      return "I'm offline, but you've got this! Keep going!";
    }
  }

  /// Sends the conversation history and returns an AI response.
  Future<ChatMessage> getCoachResponse(
    List<ChatMessage> conversationHistory,
    CoachContext context,
  ) async {
    ChatMessage assistantMessage;

    if (isApiAvailable) {
      final List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'system', 'content': 'CURRENT CONTEXT:\n${context.toContextString()}'},
      ];

      // Add recent history (up to last 10 messages to save tokens)
      final recentHistory = conversationHistory.length > 10 
          ? conversationHistory.sublist(conversationHistory.length - 10) 
          : conversationHistory;

      for (var msg in recentHistory) {
        if (msg.isUser) {
          apiMessages.add({'role': 'user', 'content': msg.content});
        } else if (msg.isAssistant) {
          apiMessages.add({'role': 'assistant', 'content': msg.content});
        }
      }

      final responseText = await _callFireworksApi(apiMessages);
      assistantMessage = ChatMessage.assistant(responseText);
    } else {
      assistantMessage = ChatMessage.assistant("I'm offline, please add your Fireworks API key to .env!");
    }

    await saveMessage(assistantMessage);
    return assistantMessage;
  }

  /// Sends live activity context and returns a proactive coaching tip.
  Future<ChatMessage> getLiveCoachingTip(CoachContext context) async {
    ChatMessage assistantMessage;

    if (isApiAvailable) {
      final prompt = 'The user is currently active.\\n\\n'
          'CURRENT CONTEXT:\\n${context.toContextString()}\\n\\n'
          'Provide a highly motivational 1-2 sentence coaching tip based on their current speed, distance, or territory.';

      final List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': prompt},
      ];

      final responseText = await _callFireworksApi(apiMessages, maxTokens: 100);
      assistantMessage = ChatMessage.assistant(responseText).copyWith(metadata: {'isLiveCoaching': true});
    } else {
      assistantMessage = ChatMessage.assistant("Keep pushing!").copyWith(metadata: {'isLiveCoaching': true});
    }

    await saveMessage(assistantMessage);
    return assistantMessage;
  }
}
