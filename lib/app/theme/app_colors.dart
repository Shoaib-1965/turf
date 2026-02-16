import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────
  static const background = Color(0xFFF0F8F7); // soft teal-white
  static const backgroundAlt = Color(0xFFE8F5F3); // slightly deeper teal-white
  static const backgroundDeep = Color(0xFFD4EDE9); // card section backgrounds

  // ── Primary Teal ─────────────────────────────────────
  static const primaryTeal = Color(
    0xFF00897B,
  ); // deep teal — buttons, icons, active
  static const accentTeal = Color(
    0xFF00BFA5,
  ); // bright teal — glows, highlights
  static const lightTeal = Color(0xFFE0F2F1); // teal 10% — chip backgrounds

  // ── Territory Colors ─────────────────────────────────
  static const ownTerritory = Color(0xFF00897B); // deep teal — owned
  static const enemyTerritory = Color(0xFFFF5252); // coral red — enemy
  static const friendTerritory = Color(0xFF29B6F6); // sky blue — friend

  // ── Text ─────────────────────────────────────────────
  static const textPrimary = Color(0xFF0D1B1A); // rich black
  static const textSecondary = Color(0xFF4A5568); // dark grey
  static const textTertiary = Color(0xFF90A4AE); // light grey

  // ── Glass ────────────────────────────────────────────
  static const glassFill = Color(0x80FFFFFF); // white 50%
  static const glassBorder = Color(0xB3FFFFFF); // white 70%
  static const glassSheen = Color(0x1A00897B); // teal 10% tint

  // ── Status / Accents ─────────────────────────────────
  static const successGreen = Color(0xFF2E7D32);
  static const warningOrange = Color(0xFFF57C00);
  static const errorRed = Color(0xFFD32F2F);
  static const goldAccent = Color(0xFFF9A825);
  static const silverAccent = Color(0xFF78909C);
  static const bronzeAccent = Color(0xFF8D6E63);
}
