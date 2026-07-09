import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

/// Full-screen overlay that celebrates a successful territory claim.
/// Shows confetti burst, area text, and auto-dismisses after 3 seconds.
class TerritoryClaimCelebration extends StatefulWidget {
  final double areaSqm;
  final VoidCallback onDismiss;

  const TerritoryClaimCelebration({
    super.key,
    required this.areaSqm,
    required this.onDismiss,
  });

  @override
  State<TerritoryClaimCelebration> createState() => _TerritoryClaimCelebrationState();
}

class _TerritoryClaimCelebrationState extends State<TerritoryClaimCelebration>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.3)),
    );

    // Trigger haptic + confetti + animation
    HapticFeedback.heavyImpact();
    _confettiController.play();
    _animationController.forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatArea(double sqm) {
    if (sqm < 10000) {
      return '${sqm.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} m²';
    }
    return '${(sqm / 10000).toStringAsFixed(1)} hectares';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return IgnorePointer(
          child: Stack(
            children: [
              // Semi-transparent background
              Positioned.fill(
                child: Opacity(
                  opacity: _opacityAnimation.value * 0.4,
                  child: Container(color: Colors.black),
                ),
              ),

              // Center celebration text
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFF00E676),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TERRITORY CLAIMED!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Space Grotesk',
                          letterSpacing: 2,
                          shadows: [
                            Shadow(color: Color(0xFF00E676), blurRadius: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00E676), width: 1),
                        ),
                        child: Text(
                          _formatArea(widget.areaSqm),
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Confetti from top center
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 30,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  gravity: 0.2,
                  colors: const [
                    Color(0xFF00E676),
                    Colors.white,
                    Colors.yellow,
                    Color(0xFF69F0AE),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
