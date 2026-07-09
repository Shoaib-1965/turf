import 'package:flutter/material.dart';
import 'package:turf_app/core/widgets/user_avatar.dart';

class UserLocationMarker extends StatelessWidget {
  final String? avatarUrl;
  final String? username;

  const UserLocationMarker({
    super.key,
    this.avatarUrl,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 44,
        height: 52, // Extra height for the triangle pin
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Triangle pin at the bottom
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: const Size(12, 10),
                painter: _TrianglePainter(color: const Color(0xFF00E676)),
              ),
            ),
            
            // The main circular avatar with glow
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676),
                border: Border.all(color: const Color(0xFF00E676), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: UserAvatar(
                size: 40,
                avatarUrl: avatarUrl,
                fullName: username,
                terraColor: '#00E676',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
