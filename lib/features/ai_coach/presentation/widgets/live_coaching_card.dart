import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/features/ai_coach/presentation/providers/ai_coach_provider.dart';
import 'package:turf_app/features/ai_coach/domain/models/chat_message.dart';
import 'package:turf_app/features/ai_coach/domain/models/coach_context.dart';
import 'package:turf_app/features/activity/presentation/providers/live_activity_provider.dart';

class LiveCoachingCard extends ConsumerStatefulWidget {
  const LiveCoachingCard({super.key});

  @override
  ConsumerState<LiveCoachingCard> createState() => _LiveCoachingCardState();
}

class _LiveCoachingCardState extends ConsumerState<LiveCoachingCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  Timer? _coachingTimer;

  @override
  void initState() {
    super.initState();
    // Request a tip every 60 seconds
    _coachingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _requestCoachingTip();
    });
    
    // Request an initial tip after a small delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _requestCoachingTip();
      }
    });
  }

  @override
  void dispose() {
    _coachingTimer?.cancel();
    super.dispose();
  }

  void _requestCoachingTip() {
    final activityState = ref.read(liveActivityProvider);
    if (activityState.status != TrackingState.active) return;

    final context = CoachContext(
      username: 'Runner', // Would normally get from profile
      level: 1,
      totalXp: 0,
      totalDistanceKm: 0,
      streakDays: 0,
      currentActivityType: activityState.activityType,
      currentSpeedKmh: activityState.currentSpeedKmh,
      currentPaceMinPerKm: activityState.currentSpeedKmh > 0 ? 60 / activityState.currentSpeedKmh : 0,
      currentDistanceKm: activityState.distanceKm,
      currentDurationSeconds: activityState.durationSeconds,
      currentCaloriesBurned: activityState.caloriesBurned,
      currentElevationGainM: activityState.elevationGainM,
      landClaimedSqm: activityState.landClaimedSqm,
      activeGoals: [],
      recentBadges: [],
      activeChallenges: [],
    );

    ref.read(aiCoachProvider.notifier).updateContext(context);
    ref.read(aiCoachProvider.notifier).sendLiveCoachingRequest();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCoachProvider);
    
    // Find the last assistant message that is a coaching tip
    final coachingMessages = aiState.messages
        .where((m) => m.role == 'assistant' && (m.metadata?['isLiveCoaching'] == true || m.id != 'welcome'))
        .toList();
        
    final lastMessage = coachingMessages.isNotEmpty ? coachingMessages.last.content : 'AI Coach ready...';

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF00E676),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isExpanded ? 'Live Coaching' : lastMessage,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: _isExpanded ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: _isExpanded ? 1 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF8E8E93),
                      size: 20,
                    ),
                  ],
                ),
                
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF2C2C2E), height: 1),
                  const SizedBox(height: 12),
                  
                  // Show last 3 messages
                  ...coachingMessages.reversed.take(3).toList().reversed.map((msg) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.fitness_center, size: 14, color: Color(0xFF8E8E93)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg.content,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFE5E5EA),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  if (aiState.isTyping)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.more_horiz, size: 14, color: Color(0xFF00E676)),
                          const SizedBox(width: 8),
                          Text(
                            'Analyzing metrics...',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00E676),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
