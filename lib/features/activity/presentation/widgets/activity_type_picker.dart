import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/features/activity/presentation/providers/live_activity_provider.dart';

class ActivityTypePicker extends ConsumerStatefulWidget {
  const ActivityTypePicker({super.key});

  @override
  ConsumerState<ActivityTypePicker> createState() => _ActivityTypePickerState();
}

class _ActivityTypePickerState extends ConsumerState<ActivityTypePicker> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<double> _bgOpacity;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _bgOpacity = Tween<double>(begin: 0.05, end: 0.12).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 1.0,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return AnimatedBuilder(
          animation: _bgOpacity,
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  // Breathing gradient background
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.5,
                          colors: [
                            const Color(0xFF00E676).withOpacity(_bgOpacity.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Content
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Choose Your Activity",
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "What are you doing today?",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: const [
                            _TypeCard(
                              type: 'run',
                              title: 'Run',
                              subtitle: 'High intensity · ~9.8 MET',
                              calories: '~420 cal/hr',
                              icon: Icons.directions_run,
                              color: Color(0xFF00E676),
                            ),
                            SizedBox(height: 16),
                            _TypeCard(
                              type: 'walk',
                              title: 'Walk',
                              subtitle: 'Low impact · ~3.5 MET',
                              calories: '~180 cal/hr',
                              icon: Icons.directions_walk,
                              color: Color(0xFF0A84FF),
                            ),
                            SizedBox(height: 16),
                            _TypeCard(
                              type: 'cycle',
                              title: 'Cycle',
                              subtitle: 'Cardio · ~7.5 MET',
                              calories: '~350 cal/hr',
                              icon: Icons.directions_bike,
                              color: Color(0xFFFF9500),
                            ),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TypeCard extends ConsumerStatefulWidget {
  final String type;
  final String title;
  final String subtitle;
  final String calories;
  final IconData icon;
  final Color color;

  const _TypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.calories,
    required this.icon,
    required this.color,
  });

  @override
  ConsumerState<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends ConsumerState<_TypeCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTap() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSelected = true);
    await _animController.forward(from: 0.0);
    
    if (mounted) {
      ref.read(liveActivityProvider.notifier).setActivityType(widget.type);
      Navigator.pop(context); // Close sheet
      context.push('/activity/countdown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSelected ? widget.color : const Color(0xFF2C2C2E),
                  width: _isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 28, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.calories,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
