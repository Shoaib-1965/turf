import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

/// 4-stat row: Total Territory | Total Runs | Total Distance | Best Pace.
class ProfileStatsRow extends StatefulWidget {
  final double territoryKm2;
  final int totalRuns;
  final double totalDistanceKm;
  final String bestPace;

  const ProfileStatsRow({
    super.key,
    required this.territoryKm2,
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.bestPace,
  });

  @override
  State<ProfileStatsRow> createState() => _ProfileStatsRowState();
}

class _ProfileStatsRowState extends State<ProfileStatsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return IntrinsicHeight(
              child: Row(
                children: [
                  _stat(
                    label: 'TERRITORY',
                    value:
                        '${(widget.territoryKm2 * _anim.value).toStringAsFixed(1)} km²',
                    isTeal: true,
                  ),
                  _divider(),
                  _stat(
                    label: 'RUNS',
                    value: '${(widget.totalRuns * _anim.value).round()}',
                  ),
                  _divider(),
                  _stat(
                    label: 'DISTANCE',
                    value:
                        '${(widget.totalDistanceKm * _anim.value).toStringAsFixed(0)} km',
                  ),
                  _divider(),
                  _stat(
                    label: 'BEST PACE',
                    value: _anim.value > 0.8 ? widget.bestPace : '--:--',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _stat({
    required String label,
    required String value,
    bool isTeal = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isTeal ? AppColors.primaryTeal : AppColors.textPrimary,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFE0F2F1),
    );
  }
}
