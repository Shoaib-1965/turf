import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile_achievements.dart';
import '../widgets/profile_hero_header.dart';
import '../widgets/profile_rank_banner.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_territory_map.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = userId ?? 'current_user';
    final asyncProfile = ref.watch(userProfileProvider(profileId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncProfile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load profile',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (profile) => _buildBody(context, profile),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile profile) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 120,
      ),
      children: [
        // ── 1. Hero Header ──────────────────────────
        ProfileHeroHeader(profile: profile).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // ── 2. Stats Row ────────────────────────────
        ProfileStatsRow(
          territoryKm2: profile.totalTerritoryKm2,
          totalRuns: profile.totalRuns,
          totalDistanceKm: profile.totalDistanceKm,
          bestPace: profile.bestPaceFormatted,
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
              begin: 0.08,
              end: 0,
              delay: 100.ms,
              duration: 400.ms,
            ),

        const SizedBox(height: 14),

        // ── 3. Global Rank Banner ───────────────────
        ProfileRankBanner(
          globalRank: profile.globalRank,
          percentile: profile.rankPercentile,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
              begin: 0.08,
              end: 0,
              delay: 200.ms,
              duration: 400.ms,
            ),

        const SizedBox(height: 14),

        // ── 4. Territory Map ────────────────────────
        ProfileTerritoryMap(
          territoryKm2: profile.totalTerritoryKm2,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
              begin: 0.08,
              end: 0,
              delay: 300.ms,
              duration: 400.ms,
            ),

        const SizedBox(height: 14),

        // ── 5. Achievements ─────────────────────────
        ProfileAchievements(
          earnedIds: profile.achievementIds,
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(
              begin: 0.08,
              end: 0,
              delay: 400.ms,
              duration: 400.ms,
            ),

        const SizedBox(height: 14),

        // ── 6. Personal Records ─────────────────────
        _personalRecords(profile)
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideY(
              begin: 0.08,
              end: 0,
              delay: 500.ms,
              duration: 400.ms,
            ),

        const SizedBox(height: 14),

        // ── 7. Recent Runs ──────────────────────────
        _recentRuns(profile)
            .animate()
            .fadeIn(delay: 600.ms, duration: 400.ms)
            .slideY(
              begin: 0.08,
              end: 0,
              delay: 600.ms,
              duration: 400.ms,
            ),
      ],
    );
  }

  // ── Personal Records ────────────────────────────────────
  Widget _personalRecords(UserProfile profile) {
    final records = [
      ('Fastest 1 km', '${profile.bestPaceFormatted}/km'),
      ('Fastest 5 km', '5:22/km'),
      ('Longest Run', '12.3 km'),
      ('Most Territory (one run)', '0.82 km²'),
      ('Best Week', '32.4 km'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERSONAL RECORDS',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...records.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AppColors.backgroundDeep,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.$1,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          r.$2,
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Recent Runs ─────────────────────────────────────────
  Widget _recentRuns(UserProfile profile) {
    final dateFormat = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECENT RUNS',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...profile.recentRuns.asMap().entries.map((entry) {
              final i = entry.key;
              final run = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: AppColors.backgroundDeep),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        // Date
                        SizedBox(
                          width: 56,
                          child: Text(
                            dateFormat.format(run.date),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        // Distance + Pace
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${run.distanceKm} km',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${run.pace}/km',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Territory chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightTeal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${run.territoryKm2} km²',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
            // "View all runs" link
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Navigate to full run history
                },
                child: Text(
                  'View all runs →',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
