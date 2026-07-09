import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Color> _slideColors = [
    const Color(0xFF00E676),
    const Color(0xFF0A84FF),
    const Color(0xFFFFD60A),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // The actual page view
          PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(), // user must swipe manually
            children: [_Slide1(), _Slide2(), _Slide3()],
          ),

          // Custom Curtain Wipe Transition Overlay
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _CurtainPainter(
                pageOffset: _currentPage,
                colors: _slideColors,
              ),
            ),
          ),

          // Skip Button
          if (_currentPage < 2.0)
            Positioned(
              top: 56,
              right: 24,
              child: GestureDetector(
                onTap: () => context.go('/auth'),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Page Indicators
          if (_currentPage < 2.0)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final active = (_currentPage.round() == index);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 12 : 8,
                    height: active ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? const Color(0xFF00E676)
                          : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? const Color(0xFF00E676)
                            : const Color(0xFF8E8E93),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOM CURTAIN PAINTER
// ─────────────────────────────────────────────
class _CurtainPainter extends CustomPainter {
  final double pageOffset;
  final List<Color> colors;

  _CurtainPainter({required this.pageOffset, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (pageOffset <= 0.0 || pageOffset >= colors.length - 1) return;

    // We draw a curtain for the fractional part of the swipe
    final currentIdx = pageOffset.floor();
    final fraction = pageOffset - currentIdx;

    if (fraction == 0.0) return;

    // As user swipes right-to-left (fraction goes 0 -> 1),
    // the curtain expands from the right side of the screen.
    final nextColor = colors[currentIdx + 1];

    final paint = Paint()..color = nextColor;

    // We want the curtain to be a solid block sliding over
    // and then receding to reveal the next page.
    // Wait, the PageView inherently slides the views. The prompt says:
    // "as user swipes, the next page reveals behind a vertical curtain wipe"
    // So we can draw a solid rectangle over the *current* page that matches the next color

    // Actually, PageView itself handles sliding. To do a "curtain" effect over a PageView,
    // we would ideally need a custom PageRouteBuilder or stack.
    // Since we are using a PageView, the views slide together.
    // We can paint a solid color wipe that masks the transition.

    // Wipe coming from right to left
    // fraction 0.0 -> 0.5: curtain covers the screen from right to left
    // fraction 0.5 -> 1.0: curtain recedes left to right revealing the next page

    Path curtainPath = Path();
    if (fraction <= 0.5) {
      // Expanding from right
      final width = size.width * (fraction * 2);
      curtainPath.addRect(
        Rect.fromLTWH(size.width - width, 0, width, size.height),
      );
    } else {
      // Receding to left
      final width = size.width * ((1.0 - fraction) * 2);
      curtainPath.addRect(Rect.fromLTWH(0, 0, width, size.height));
    }

    canvas.drawPath(curtainPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CurtainPainter oldDelegate) {
    return oldDelegate.pageOffset != pageOffset;
  }
}

// ─────────────────────────────────────────────
// SLIDE 1 WIDGET & PAINTER
// ─────────────────────────────────────────────
class _Slide1 extends StatefulWidget {
  @override
  State<_Slide1> createState() => _Slide1State();
}

class _Slide1State extends State<_Slide1> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _HexagonCityPainter(_ctrl.value),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Text(
                  'Claim Your Territory',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Run through your city and own every street you touch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HexagonCityPainter extends CustomPainter {
  final double progress;
  _HexagonCityPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw city grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1C1C1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Hexagons
    final hexRadius = 35.0;
    final dx = hexRadius * 1.5;
    final dy = hexRadius * sqrt(3);

    // List of hex coordinates relative to center
    final hexes = [
      Offset(0, 0),
      Offset(dx, dy / 2),
      Offset(dx, -dy / 2),
      Offset(0, -dy),
      Offset(-dx, -dy / 2),
      Offset(-dx, dy / 2),
      Offset(0, dy),
    ];

    for (int i = 0; i < hexes.length; i++) {
      final h = hexes[i];
      final center = Offset(cx + h.dx, cy + h.dy);

      // Calculate stagger
      final delay = i * 0.1;
      final p = (progress * 2.0 - delay).clamp(0.0, 1.0);

      if (p > 0) {
        final path = Path();
        for (int j = 0; j < 6; j++) {
          final angle = j * pi / 3;
          final point = Offset(
            center.dx + hexRadius * cos(angle),
            center.dy + hexRadius * sin(angle),
          );
          if (j == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();

        final fillPaint = Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: p * 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);

        final strokePaint = Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: p)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexagonCityPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────
// SLIDE 2 WIDGET & PAINTER
// ─────────────────────────────────────────────
class _Slide2 extends StatefulWidget {
  @override
  State<_Slide2> createState() => _Slide2State();
}

class _Slide2State extends State<_Slide2> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _SquadPainter(_ctrl.value),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Text(
                  'Run With Your Squad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Challenge friends to live group runs. First to the territory wins.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SquadPainter extends CustomPainter {
  final double progress;
  _SquadPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final target = Offset(cx, cy - 40);

    // Glowing territory
    canvas.drawCircle(
      target,
      40,
      Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      target,
      40,
      Paint()
        ..color = const Color(0xFF00E676)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 3 Avatars converging
    final starts = [
      Offset(cx - 100, cy + 150),
      Offset(cx + 100, cy + 120),
      Offset(cx, cy + 180),
    ];
    final colors = [
      const Color(0xFF0A84FF),
      const Color(0xFFFFD60A),
      const Color(0xFFFF453A),
    ];

    for (int i = 0; i < 3; i++) {
      final p = (progress * 1.5 - i * 0.1).clamp(0.0, 1.0);

      // Calculate current position along curve
      final currentPos = Offset.lerp(
        starts[i],
        target,
        Curves.easeOut.transform(p),
      )!;

      // Draw trail
      if (p > 0) {
        final path = Path()
          ..moveTo(starts[i].dx, starts[i].dy)
          ..lineTo(currentPos.dx, currentPos.dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = colors[i].withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }

      // Draw avatar circle
      if (p > 0 && p < 1.0) {
        canvas.drawCircle(currentPos, 16, Paint()..color = colors[i]);
        canvas.drawCircle(
          currentPos,
          16,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SquadPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────
// SLIDE 3 WIDGET & PAINTER
// ─────────────────────────────────────────────
class _Slide3 extends StatefulWidget {
  @override
  State<_Slide3> createState() => _Slide3State();
}

class _Slide3State extends State<_Slide3> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _PodiumPainter(_ctrl.value),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Text(
                  'Rise to the Top',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Earn XP, unlock badges, and dominate the leaderboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/auth'),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PodiumPainter extends CustomPainter {
  final double progress;
  _PodiumPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 50;

    // Draw podiums
    final p1 = Curves.easeOutBack.transform((progress * 2).clamp(0.0, 1.0));
    final p2 = Curves.easeOutBack.transform(
      (progress * 2 - 0.2).clamp(0.0, 1.0),
    );
    final p3 = Curves.easeOutBack.transform(
      (progress * 2 - 0.4).clamp(0.0, 1.0),
    );

    final paint1 = Paint()..color = const Color(0xFF00E676);
    final paint2 = Paint()..color = const Color(0xFF2C2C2E);
    final paint3 = Paint()..color = const Color(0xFF1C1C1E);

    // 2nd place (left)
    canvas.drawRRect(
      RRect.fromLTRBR(
        cx - 90,
        cy - 60 * p2,
        cx - 30,
        cy,
        const Radius.circular(8),
      ),
      paint2,
    );
    // 3rd place (right)
    canvas.drawRRect(
      RRect.fromLTRBR(
        cx + 30,
        cy - 40 * p3,
        cx + 90,
        cy,
        const Radius.circular(8),
      ),
      paint3,
    );
    // 1st place (center)
    canvas.drawRRect(
      RRect.fromLTRBR(
        cx - 30,
        cy - 100 * p1,
        cx + 30,
        cy,
        const Radius.circular(8),
      ),
      paint1,
    );

    // Confetti
    if (progress > 0.5) {
      final cp = (progress - 0.5) * 2.0;
      final rand = Random(42);
      for (int i = 0; i < 30; i++) {
        final x = cx + (rand.nextDouble() - 0.5) * 200;
        final startY = cy - 200 + rand.nextDouble() * 50;
        final y = startY + cp * 200;

        final color = [
          const Color(0xFF00E676),
          Colors.white,
          const Color(0xFFFFD60A),
        ][rand.nextInt(3)];
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = color.withValues(alpha: 1.0 - cp),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PodiumPainter oldDelegate) => true;
}
