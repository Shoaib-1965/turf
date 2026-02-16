import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // ── Display — Bebas Neue ─────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.bebasNeue(
    fontSize: 48,
    color: AppColors.textPrimary,
    letterSpacing: 2.0,
  );

  static TextStyle get displayMedium => GoogleFonts.bebasNeue(
    fontSize: 32,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  // ── Headlines — DM Sans ──────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.dmSans(
    fontSize: 24,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get headlineMedium => GoogleFonts.dmSans(
    fontSize: 20,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
  );

  // ── Body — DM Sans ───────────────────────────────────
  static TextStyle get bodyLarge =>
      GoogleFonts.dmSans(fontSize: 16, color: AppColors.textPrimary);

  static TextStyle get bodyMedium =>
      GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary);

  // ── Stats — Roboto Mono ──────────────────────────────
  static TextStyle get statLarge => GoogleFonts.robotoMono(
    fontSize: 36,
    color: AppColors.primaryTeal,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get statMedium => GoogleFonts.robotoMono(
    fontSize: 24,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get statSmall =>
      GoogleFonts.robotoMono(fontSize: 14, color: AppColors.textSecondary);

  // ── Label ────────────────────────────────────────────
  static TextStyle get labelChip => GoogleFonts.dmSans(
    fontSize: 12,
    color: AppColors.primaryTeal,
    fontWeight: FontWeight.w600,
  );
}
