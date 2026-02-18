import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_filter_chips.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_tab_bar.dart';
import '../widgets/leaderboard_tile.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardTab _tab = LeaderboardTab.global;
  LeaderboardPeriod _period = LeaderboardPeriod.thisMonth;

  LeaderboardKey get _key => (tab: _tab, period: _period);

  @override
  Widget build(BuildContext context) {
    final asyncEntries = ref.watch(leaderboardProvider(_key));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'LEADERBOARD',
        centerTitle: true,
        actions: [_seasonChip()],
      ),
      // extendBodyBehindAppBar: true,
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ── Filter chips ─────────────────────────────
          LeaderboardFilterChips(
            selected: _period,
            onSelected: (p) => setState(() => _period = p),
          ),

          const SizedBox(height: 14),

          // ── Tab bar ──────────────────────────────────
          LeaderboardTabBar(
            selected: _tab,
            onSelected: (t) => setState(() => _tab = t),
          ),

          const SizedBox(height: 16),

          // ── Content ──────────────────────────────────
          Expanded(
            child: asyncEntries.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
              error: (e, _) => Center(
                child: Text('Something went wrong',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
              ),
              data: (entries) => _buildList(entries),
            ),
          ),
        ],
      ),
    );
  }

  // ── Season chip ──────────────────────────────────────────
  Widget _seasonChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GlassCard(
        borderRadius: 20,
        blur: 12,
        fillOpacity: 0.55,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 14, color: AppColors.primaryTeal),
            const SizedBox(width: 6),
            Text(
              '14d left',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main scrollable list ─────────────────────────────────
  Widget _buildList(List<LeaderboardEntry> entries) {
    final top3 = entries.where((e) => e.rank <= 3).toList();
    final rest = entries.where((e) => e.rank > 3).toList();

    // Check if current user is in the visible rest list
    final currentUserInRest = rest.any((e) => e.isCurrentUser);
    final currentUserEntry = entries.where((e) => e.isCurrentUser).firstOrNull;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              // ── Podium ────────────────────────────
              if (top3.length >= 3)
                LeaderboardPodium(top3: top3)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms),

              const SizedBox(height: 12),

              // ── Ranked list ───────────────────────
              ...List.generate(rest.length, (i) {
                return LeaderboardTile(entry: rest[i])
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 40 * i),
                      duration: 350.ms,
                    )
                    .slideX(
                      begin: 0.15,
                      end: 0,
                      delay: Duration(milliseconds: 40 * i),
                      duration: 350.ms,
                      curve: Curves.easeOut,
                    );
              }),
            ],
          ),
        ),

        // ── Pinned current user row (if not visible) ────
        if (!currentUserInRest && currentUserEntry != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1, color: AppColors.backgroundDeep),
              LeaderboardTile(entry: currentUserEntry),
              const SizedBox(height: 4),
            ],
          ),
      ],
    );
  }
}
