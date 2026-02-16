import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

extension ContextExtensions on BuildContext {
  // ── Theme Shortcuts ──────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // ── Screen Dimensions ────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  // ── Responsive Breakpoints ───────────────────────────
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  bool get isLargeScreen => screenWidth >= 600;

  // ── Typography Shortcuts ─────────────────────────────
  TextStyle get displayLarge => AppTypography.displayLarge;
  TextStyle get displayMedium => AppTypography.displayMedium;
  TextStyle get headlineLarge => AppTypography.headlineLarge;
  TextStyle get headlineMedium => AppTypography.headlineMedium;
  TextStyle get bodyLarge => AppTypography.bodyLarge;
  TextStyle get bodyMedium => AppTypography.bodyMedium;
  TextStyle get statLarge => AppTypography.statLarge;
  TextStyle get statMedium => AppTypography.statMedium;
  TextStyle get statSmall => AppTypography.statSmall;
  TextStyle get labelChip => AppTypography.labelChip;

  // ── Snack Bar ────────────────────────────────────────
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }
}
