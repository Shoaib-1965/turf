import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:turf_app/features/ai_coach/data/ai_coach_repository.dart';
import 'package:turf_app/features/ai_coach/domain/models/chat_message.dart';
import 'package:turf_app/features/ai_coach/domain/models/coach_context.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AiCoachState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;
  final CoachContext coachContext;
  final bool isTtsEnabled;

  const AiCoachState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
    required this.coachContext,
    this.isTtsEnabled = true,
  });

  AiCoachState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
    CoachContext? coachContext,
    bool? isTtsEnabled,
  }) {
    return AiCoachState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      error: error,
      coachContext: coachContext ?? this.coachContext,
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final aiCoachRepositoryProvider = Provider<AiCoachRepository>(
  (ref) => AiCoachRepository(),
);

final aiCoachProvider =
    NotifierProvider<AiCoachNotifier, AiCoachState>(AiCoachNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AiCoachNotifier extends Notifier<AiCoachState> {
  static const _welcomeText =
      "Hey! 👋 I'm your TURF Coach powered by Gemma AI. I can help you with "
      "running tips, nutrition advice, territory strategy, and more. "
      "What would you like to know?";

  static final _defaultContext = CoachContext(
    currentActivityType: 'run',
    currentDistanceKm: 0,
    currentDurationSeconds: 0,
    currentSpeedKmh: 0,
    currentCaloriesBurned: 0,
    currentElevationGainM: 0,
  );

  final FlutterTts _flutterTts = FlutterTts();

  @override
  AiCoachState build() {
    _initTts();
    
    // Start by loading history
    _loadHistory();

    return AiCoachState(
      messages: [],
      isLoading: true,
      coachContext: _defaultContext,
    );
  }

  AiCoachRepository get _repo => ref.read(aiCoachRepositoryProvider);

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadHistory() async {
    final history = await _repo.getChatHistory();
    
    if (history.isEmpty) {
      // Create and save welcome message if empty
      final welcomeMsg = ChatMessage.assistant(_welcomeText);
      await _repo.saveMessage(welcomeMsg);
      state = state.copyWith(
        messages: [welcomeMsg],
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        messages: history,
        isLoading: false,
      );
    }
  }

  Future<void> _speakTip(String text) async {
    if (state.isTtsEnabled) {
      // Remove emojis and formatting for cleaner speech
      final cleanText = text
        .replaceAll(RegExp(r'\*\*.*?\*\*'), '') // Remove bold asterisks
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F6FF}]', unicode: true), '') // Remove basic emojis
        .replaceAll(RegExp(r'[\u{1F900}-\u{1F9FF}]', unicode: true), '') // Remove extended emojis
        .replaceAll('•', '')
        .replaceAll('*', '')
        .trim();
        
      await _flutterTts.speak(cleanText);
    }
  }

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  void toggleTts() {
    state = state.copyWith(isTtsEnabled: !state.isTtsEnabled);
    if (!state.isTtsEnabled) {
      _flutterTts.stop();
    }
  }

  /// Sends a user message and retrieves the AI assistant response.
  Future<void> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty || state.isTyping) return;

    final userMessage = ChatMessage.user(text);
    
    // Save user message immediately to Supabase
    await _repo.saveMessage(userMessage);

    // Append user message and show typing indicator.
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      error: null,
    );

    try {
      final response = await _repo.getCoachResponse(state.messages, state.coachContext);

      state = state.copyWith(
        messages: [...state.messages, response],
        isTyping: false,
      );
      
      _speakTip(response.content);
      
    } catch (e) {
      final errorMessage = ChatMessage.error(
        "Sorry, I couldn't process that. Please try again.",
      );
      
      await _repo.saveMessage(errorMessage);

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  /// Requests a proactive coaching tip using the current live context.
  /// No user message is added — the AI initiates the response.
  Future<void> sendLiveCoachingRequest() async {
    if (state.isTyping) return;

    state = state.copyWith(isTyping: true, error: null);

    try {
      final tip = await _repo.getLiveCoachingTip(state.coachContext);

      state = state.copyWith(
        messages: [...state.messages, tip],
        isTyping: false,
      );
      
      _speakTip(tip.content);
      
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  /// Updates the live coaching context (called from the live activity screen).
  void updateContext(CoachContext context) {
    state = state.copyWith(coachContext: context);
  }

  /// Resets the chat to its initial welcome state (clears local state, does not delete from DB).
  void clearChat() {
    state = state.copyWith(
      messages: [],
    );
    _loadHistory();
  }
}
