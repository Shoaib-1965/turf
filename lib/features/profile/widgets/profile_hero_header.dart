import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../models/user_profile.dart';

/// Gradient hero header with avatar, username, bio, and edit/follow chip.
class ProfileHeroHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onEditTap;
  final VoidCallback? onFollowTap;
  final bool isFollowing;

  const ProfileHeroHeader({
    super.key,
    required this.profile,
    this.onEditTap,
    this.onFollowTap,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00897B).withValues(alpha: 0.15),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              // ── Top row: back + action chip ───────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (only if can pop)
                  Builder(builder: (ctx) {
                    if (Navigator.of(ctx).canPop()) {
                      return IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20),
                        color: AppColors.primaryTeal,
                        onPressed: () => Navigator.pop(ctx),
                      );
                    }
                    return const SizedBox(width: 48);
                  }),
                  // Edit / Follow chip
                  if (profile.isOwnProfile)
                    _glassChip(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      onTap: onEditTap,
                    )
                  else
                    _followChip(),
                ],
              ),

              const SizedBox(height: 8),

              // ── Avatar ────────────────────────────
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.20),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: profile.isOwnProfile ? onEditTap : null,
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 39,
                      backgroundColor: AppColors.backgroundAlt,
                      backgroundImage: NetworkImage(profile.photoUrl),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Username ──────────────────────────
              Text(
                profile.username.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 30,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 4),

              // ── Bio ───────────────────────────────
              Text(
                profile.bio,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.primaryTeal),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _followChip() {
    return GestureDetector(
      onTap: onFollowTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryTeal,
            width: 1.5,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isFollowing ? AppColors.primaryTeal : Colors.white,
          ),
        ),
      ),
    );
  }
}
