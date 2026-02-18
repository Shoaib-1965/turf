import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/competition_model.dart';
import '../providers/competition_provider.dart';

/// Active competition hero card with shimmer border, countdown, entries & probability.
class CompetitionHeroCard extends ConsumerStatefulWidget {
  final CompetitionModel competition;
  final VoidCallback onClaimTap;

  const CompetitionHeroCard({
    super.key,
    required this.competition,
    required this.onClaimTap,
  });

  @override
  ConsumerState<CompetitionHeroCard> createState() =>
      _CompetitionHeroCardState();
}

class _CompetitionHeroCardState extends ConsumerState<CompetitionHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countdown = ref.watch(countdownProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: SweepGradient(
                center: Alignment.center,
                startAngle: 0,
                endAngle: 6.28,
                transform: GradientRotation(_shimmerCtrl.value * 6.28),
                colors: const [
                  AppColors.primaryTeal,
                  AppColors.goldAccent,
                  AppColors.accentTeal,
                  AppColors.primaryTeal,
                ],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ACTIVE chip ─────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Prize image ─────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      color: AppColors.backgroundAlt,
                      child: Image.network(
                        widget.competition.prizeImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.emoji_events_rounded,
                              size: 64, color: AppColors.primaryTeal),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Prize name ──────────────────────
                  Text(
                    widget.competition.prizeName,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 28,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Countdown ───────────────────────
                  countdown.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (dur) => _countdown(dur),
                  ),

                  const SizedBox(height: 16),

                  // ── Entries ─────────────────────────
                  Row(
                    children: [
                      const Text('🎟️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'You have ${widget.competition.userEntries} entries',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1 km² claimed = 1 entry',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Win probability bar ─────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.competition.winProbability,
                      minHeight: 5,
                      backgroundColor: AppColors.lightTeal,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your win chance: ~${(widget.competition.winProbability * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── CTA Button ──────────────────────
                  GestureDetector(
                    onTap: widget.onClaimTap,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryTeal.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Claim More Territory →',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _countdown(Duration dur) {
    final days = dur.inDays;
    final hours = dur.inHours % 24;
    final minutes = dur.inMinutes % 60;
    final seconds = dur.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _countdownChip('$days', 'DAYS'),
        _countdownChip(hours.toString().padLeft(2, '0'), 'HRS'),
        _countdownChip(minutes.toString().padLeft(2, '0'), 'MIN'),
        _countdownChip(seconds.toString().padLeft(2, '0'), 'SEC'),
      ],
    );
  }

  Widget _countdownChip(String value, String label) {
    return GlassCard(
      fillOpacity: 0.60,
      borderRadius: 14,
      blur: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
