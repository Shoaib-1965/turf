import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_modal.dart';

/// "End your run?" confirmation modal.
class StopConfirmationModal {
  StopConfirmationModal._();

  static Future<bool> show(
    BuildContext context, {
    required String distance,
    required String territory,
  }) async {
    final result = await GlassModal.show<bool>(
      context: context,
      initialChildSize: 0.32,
      minChildSize: 0.25,
      maxChildSize: 0.45,
      child: _Content(distance: distance, territory: territory),
    );
    return result ?? false;
  }
}

class _Content extends StatelessWidget {
  final String distance;
  final String territory;

  const _Content({required this.distance, required this.territory});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title ─────────────────────────────────────────
        Text(
          'End your run?',
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // ── Subtitle ──────────────────────────────────────
        Text(
          "You've run $distance km and claimed $territory km²",
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        // ── Buttons ───────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: GlassButton(
                text: 'CANCEL',
                style: GlassButtonStyle.secondary,
                height: 50,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                text: 'END RUN',
                style: GlassButtonStyle.danger,
                height: 50,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
