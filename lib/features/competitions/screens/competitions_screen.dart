import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../providers/competition_provider.dart';
import '../widgets/competition_hero_card.dart';
import '../widgets/competition_stats_card.dart';
import '../widgets/how_it_works_card.dart';
import '../widgets/past_competition_tile.dart';

class CompetitionsScreen extends ConsumerWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComp = ref.watch(competitionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(title: 'COMPETITIONS'),
      body: asyncComp.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load competitions',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (comp) => ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 120,
          ),
          children: [
            const SizedBox(height: 12),

            // ── 1. Active competition hero ──────────
            CompetitionHeroCard(
              competition: comp,
              onClaimTap: () => context.go('/home'),
            ).animate().fadeIn(duration: 500.ms).slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 500.ms,
                ),

            const SizedBox(height: 18),

            // ── 2. How it works ─────────────────────
            const HowItWorksCard()
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.08, end: 0, delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 18),

            // ── 3. Past competitions header ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'PAST COMPETITIONS',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 8),

            // ── Past competition cards ──────────────
            ...List.generate(comp.pastCompetitions.length, (i) {
              return PastCompetitionTile(
                competition: comp.pastCompetitions[i],
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 350 + 60 * i),
                    duration: 350.ms,
                  )
                  .slideX(
                    begin: 0.12,
                    end: 0,
                    delay: Duration(milliseconds: 350 + 60 * i),
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  );
            }),

            const SizedBox(height: 18),

            // ── 4. My stats ─────────────────────────
            const CompetitionStatsCard()
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.08, end: 0, delay: 500.ms, duration: 400.ms),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
