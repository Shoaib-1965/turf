import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // ── Shared divider ─────────────────────────────────────
  static const _divider = Divider(
    height: 1,
    thickness: 1,
    color: Color(0xFFE0F2F1),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(title: 'SETTINGS'),
      body: ListView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 40,
        ),
        children: [
          // ── 1. ACCOUNT ─────────────────────────────
          _sectionTitle('ACCOUNT'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _navRow(context, Icons.person_rounded, 'Edit Profile',
                    onTap: () {}),
                _divider,
                _navRow(context, Icons.camera_alt_rounded, 'Change Avatar',
                    onTap: () {}),
                _divider,
                _navRow(context, Icons.alternate_email_rounded, 'Username',
                    trailing: Text('TurfPro',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ))),
                _divider,
                _navRow(context, Icons.email_rounded, 'Email',
                    trailing: Text('u***@mail.com',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ))),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

          // ── 2. CONNECTED APPS ──────────────────────
          _sectionTitle('CONNECTED APPS'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _switchRow(Icons.directions_run_rounded, 'Strava',
                    subtitle: 'Auto-upload runs to Strava',
                    value: s.stravaConnected, onChanged: (v) {
                  n.setStrava(v);
                  if (v) _showSnack(context, 'Strava connected!');
                }),
                _divider,
                _switchRow(Icons.favorite_rounded, 'Apple Health',
                    value: s.appleHealthConnected, onChanged: (v) {
                  n.setAppleHealth(v);
                  if (v) _showSnack(context, 'Apple Health connected!');
                }),
                _divider,
                _switchRow(Icons.fitness_center_rounded, 'Google Fit',
                    value: s.googleFitConnected, onChanged: (v) {
                  n.setGoogleFit(v);
                  if (v) _showSnack(context, 'Google Fit connected!');
                }),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          // ── 3. SMARTWATCH ──────────────────────────
          _sectionTitle('SMARTWATCH'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _navRow(context, Icons.watch_rounded, 'Garmin',
                    trailing: _setupLabel()),
                _divider,
                _navRow(context, Icons.watch_rounded, 'Apple Watch',
                    trailing: _setupLabel()),
                _divider,
                _navRow(context, Icons.watch_rounded, 'Polar / Suunto / Coros',
                    trailing: _setupLabel()),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

          // ── 4. MAP PREFERENCES ─────────────────────
          _sectionTitle('MAP PREFERENCES'),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Map style dropdown
                Row(
                  children: [
                    Icon(Icons.map_rounded,
                        size: 22, color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Text('Map Style',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: AppColors.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75)),
                      ),
                      child: DropdownButton<String>(
                        value: s.mapStyle,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textPrimary),
                        dropdownColor: const Color(0xFFF0F8F7),
                        items: ['Light', 'Satellite', 'Terrain']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        color: e == s.mapStyle
                                            ? AppColors.primaryTeal
                                            : AppColors.textPrimary,
                                        fontWeight: e == s.mapStyle
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      )),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) n.setMapStyle(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _divider,
                const SizedBox(height: 14),

                // Territory opacity slider
                Row(
                  children: [
                    Icon(Icons.opacity_rounded,
                        size: 22, color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Text('Territory Opacity',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text(
                      '${(s.territoryOpacity * 100).round()}%',
                      style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primaryTeal,
                    inactiveTrackColor: AppColors.lightTeal,
                    thumbColor: AppColors.primaryTeal,
                    overlayColor: AppColors.primaryTeal.withValues(alpha: 0.12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: s.territoryOpacity,
                    min: 0,
                    max: 1,
                    onChanged: n.setTerritoryOpacity,
                  ),
                ),

                _divider,
                _switchRow(Icons.people_rounded, 'Show Friends Territory',
                    value: s.showFriendsTerritory,
                    onChanged: n.setShowFriends,
                    padded: false),
                _divider,
                _switchRow(Icons.shield_rounded, 'Show Enemy Territory',
                    value: s.showEnemyTerritory,
                    onChanged: n.setShowEnemy,
                    padded: false),
                _divider,
                const SizedBox(height: 10),

                // Distance unit segmented
                Row(
                  children: [
                    Icon(Icons.straighten_rounded,
                        size: 22, color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Text('Distance Unit',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: AppColors.textPrimary)),
                    const Spacer(),
                    _segmentButton(
                      labels: ['km', 'miles'],
                      selectedIndex: s.useKm ? 0 : 1,
                      onTap: (i) => n.setUseKm(i == 0),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          // ── 5. NOTIFICATIONS ───────────────────────
          _sectionTitle('NOTIFICATIONS'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _switchRow(Icons.warning_amber_rounded, 'Territory Stolen',
                    value: s.notifyTerritoryStolen,
                    onChanged: n.setNotifyTerritoryStolen),
                _divider,
                _switchRow(Icons.group_rounded, 'Friend Activity',
                    value: s.notifyFriendActivity,
                    onChanged: n.setNotifyFriendActivity),
                _divider,
                _switchRow(Icons.emoji_events_rounded, 'Competition Updates',
                    value: s.notifyCompetitionUpdates,
                    onChanged: n.setNotifyCompetitionUpdates),
                _divider,
                _switchRow(Icons.bar_chart_rounded, 'Weekly Summary',
                    value: s.notifyWeeklySummary,
                    onChanged: n.setNotifyWeeklySummary),
                _divider,
                _switchRow(
                    Icons.notifications_active_rounded, 'Training Reminders',
                    value: s.notifyTrainingReminders,
                    onChanged: n.setNotifyTrainingReminders),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

          // ── 6. PRIVACY ─────────────────────────────
          _sectionTitle('PRIVACY'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _switchRow(Icons.visibility_off_rounded, 'Hide My Territory',
                    subtitle: "Others can't see your territory",
                    value: s.hideTerritory,
                    onChanged: n.setHideTerritory),
                _divider,
                _switchRow(Icons.lock_rounded, 'Private Profile',
                    value: s.privateProfile, onChanged: n.setPrivateProfile),
                _divider,
                _switchRow(Icons.leaderboard_rounded, 'Hide from Leaderboard',
                    value: s.hideFromLeaderboard,
                    onChanged: n.setHideFromLeaderboard),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

          // ── 7. ABOUT ───────────────────────────────
          _sectionTitle('ABOUT'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _navRow(context, Icons.info_outline_rounded, 'App Version',
                    trailing: Text('1.0.0',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textTertiary))),
                _divider,
                _navRow(context, Icons.privacy_tip_outlined, 'Privacy Policy',
                    onTap: () {}),
                _divider,
                _navRow(context, Icons.description_outlined, 'Terms of Service',
                    onTap: () {}),
                _divider,
                _navRow(context, Icons.star_rounded, 'Rate TURF ⭐',
                    onTap: () {}),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

          // ── 8. DANGER ZONE ─────────────────────────
          _sectionTitle('DANGER ZONE'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Red left accent
                  Container(
                    width: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _dangerRow(context, 'Sign Out', () {
                          _showConfirmModal(
                            context,
                            title: 'Sign Out',
                            message:
                                'Are you sure you want to sign out? You can sign back in anytime.',
                            confirmLabel: 'Sign Out',
                          );
                        }),
                        _divider,
                        _dangerRow(context, 'Delete Account', () {
                          _showDeleteModal(context);
                        }, isDestructive: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HELPER BUILDERS
  // ═══════════════════════════════════════════════════════

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _navRow(
    BuildContext context,
    IconData icon,
    String label, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 15, color: AppColors.textPrimary)),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(
    IconData icon,
    String label, {
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool padded = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: padded ? 14 : 0,
        vertical: padded ? 6 : 4,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 15, color: AppColors.textPrimary)),
                if (subtitle != null)
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? AppColors.primaryTeal
                    : null),
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? AppColors.lightTeal
                    : null),
          ),
        ],
      ),
    );
  }

  Widget _setupLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('View Setup Guide',
            style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded,
            size: 18, color: AppColors.textTertiary),
      ],
    );
  }

  Widget _segmentButton({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isActive = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labels[i],
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _dangerRow(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              isDestructive
                  ? Icons.delete_forever_rounded
                  : Icons.logout_rounded,
              size: 22,
              color: AppColors.errorRed,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isDestructive ? AppColors.errorRed : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showConfirmModal(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(title,
                    style: GoogleFonts.bebasNeue(
                        fontSize: 28, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Text(message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.75)),
                          ),
                          child: Center(
                            child: Text('Cancel',
                                style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(confirmLabel,
                                style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DeleteAccountSheet(),
    );
  }
}

// ── Delete Account Sheet (stateful for text-field) ───────
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _ctrl = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Delete Account',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 28, color: AppColors.errorRed)),
              const SizedBox(height: 10),
              Text(
                'This action is permanent. Type "DELETE" to confirm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.30),
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) =>
                      setState(() => _confirmed = v.trim() == 'DELETE'),
                  style: GoogleFonts.robotoMono(
                      fontSize: 16, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type DELETE',
                    hintStyle: GoogleFonts.robotoMono(
                        fontSize: 16, color: AppColors.textTertiary),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.75)),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _confirmed ? () => Navigator.pop(context) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        decoration: BoxDecoration(
                          color: _confirmed
                              ? AppColors.errorRed
                              : AppColors.errorRed.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('Delete',
                              style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
