import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' if (dart.library.html) 'package:turf_app/core/utils/platform_utils.dart';
import 'package:http/http.dart' as http;

/// Manages caching and registration of avatar images as Mapbox style pattern images.
/// Each user's avatar is registered once by userId, and reused across all their territories.
class StyleImageCache {
  final MapboxMap mapboxMap;
  final Set<String> _registeredImageIds = {};

  StyleImageCache(this.mapboxMap);

  /// Register an avatar image for [userId] as a Mapbox style image.
  /// If [avatarUrl] is null or fails, generates a colored-initial fallback.
  /// Returns the imageId used for the pattern.
  Future<String> registerAvatar({
    required String userId,
    String? avatarUrl,
    String? displayName,
    String colorHex = '#00E676',
  }) async {
    final imageId = 'avatar_$userId';

    // Already registered — skip
    if (_registeredImageIds.contains(imageId)) return imageId;

    Uint8List? imageBytes;

    // Try downloading the avatar
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(avatarUrl)).timeout(
          const Duration(seconds: 5),
        );
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        }
      } catch (_) {
        // Fallback below
      }
    }

    // If download failed, generate a colored-initial image
    imageBytes ??= await _generateInitialImage(
      displayName ?? '?',
      _parseColor(colorHex),
    );

    try {
      // Decode image to get dimensions
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Convert to RGBA byte data
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      if (byteData == null) return imageId;

      final mbxImage = MbxImage(
        width: image.width,
        height: image.height,
        data: byteData.buffer.asUint8List(),
      );

      await mapboxMap.style.addStyleImage(
        imageId,
        1.0, // scale
        mbxImage,
        false, // sdf
        [], // stretchX
        [], // stretchY
        null, // content
      );

      _registeredImageIds.add(imageId);
    } catch (_) {
      // Graceful fallback — territory will render without pattern
    }

    return imageId;
  }

  /// Generate a simple colored circle with the user's initial.
  Future<Uint8List> _generateInitialImage(String name, Color color) async {
    final size = const ui.Size(128, 128);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
    final paint = Paint()..color = color.withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Initial letter
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.bold,
          fontFamily: 'Space Grotesk',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// Check if we already have a pattern registered for this user.
  bool hasImage(String userId) => _registeredImageIds.contains('avatar_$userId');

  /// Clear all cached registrations (e.g. on map dispose).
  void clear() => _registeredImageIds.clear();
}
