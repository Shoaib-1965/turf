import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/social_post.dart';

/// A single post card for the social feed. Handles run, milestone, achievement types.
class FeedPostCard extends StatefulWidget {
  final SocialPost post;
  final VoidCallback? onCommentTap;

  const FeedPostCard({
    super.key,
    required this.post,
    this.onCommentTap,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAchievement = widget.post.type == SocialPostType.achievement;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Teal left accent for achievements
              if (isAchievement)
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 12),
                      _body(),
                      const SizedBox(height: 12),
                      _footer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────
  Widget _header() {
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.backgroundAlt,
          backgroundImage: NetworkImage(widget.post.photoUrl),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.username,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.post.timeAgo,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!widget.post.isFollowing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryTeal, width: 1.5),
            ),
            child: Text(
              'Follow',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
      ],
    );
  }

  // ── BODY ─────────────────────────────────────────────
  Widget _body() {
    switch (widget.post.type) {
      case SocialPostType.run:
        return _runBody();
      case SocialPostType.territoryMilestone:
        return _milestoneBody();
      case SocialPostType.achievement:
        return _achievementBody();
    }
  }

  Widget _runBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map preview
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 150,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(33.6844, 73.0479),
                initialZoom: 14,
                interactionOptions:
                    InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'com.turf.app',
                  retinaMode: true,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: const [
                        LatLng(33.682, 73.045),
                        LatLng(33.684, 73.048),
                        LatLng(33.687, 73.050),
                        LatLng(33.685, 73.053),
                      ],
                      color: AppColors.primaryTeal,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Stats chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (widget.post.distanceKm != null)
              _statChip('${widget.post.distanceKm} km'),
            if (widget.post.duration != null) _statChip(widget.post.duration!),
            if (widget.post.pace != null) _statChip('${widget.post.pace}/km'),
            if (widget.post.territoryKm2 != null)
              _statChip('${widget.post.territoryKm2} km²'),
          ],
        ),
        if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.post.caption!,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _milestoneBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pin_drop_rounded,
                size: 32, color: AppColors.primaryTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Claimed ${widget.post.totalTerritory} km² total!',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ((widget.post.totalTerritory ?? 0) / 10).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.lightTeal,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryTeal),
          ),
        ),
        if (widget.post.caption != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.post.caption!,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _achievementBody() {
    return Row(
      children: [
        Text(widget.post.badgeEmoji ?? '🏆',
            style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earned ${widget.post.badgeName}!',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.post.badgeDescription != null)
                Text(
                  widget.post.badgeDescription!,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightTeal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  // ── FOOTER ───────────────────────────────────────────
  Widget _footer() {
    return Row(
      children: [
        // Like button
        GestureDetector(
          onTap: _toggleLike,
          child: AnimatedScale(
            scale: _isLiked ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: _isLiked ? AppColors.errorRed : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_likeCount',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Comment
        GestureDetector(
          onTap: widget.onCommentTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 20, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${widget.post.comments}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Share
        Icon(Icons.share_rounded, size: 20, color: AppColors.textTertiary),
      ],
    );
  }
}
