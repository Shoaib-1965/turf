import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../providers/social_feed_provider.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/discover_grid.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/live_friends_strip.dart';
import '../widgets/search_sheet.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'COMMUNITY',
        actions: [
          IconButton(
            icon:
                const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
            onPressed: () => SearchSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // ── Tab bar ─────────────────────────────
          _buildTabBar(),

          const SizedBox(height: 12),

          // ── Body ────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tabIndex == 0 ? _feedTab() : _discoverTab(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: List.generate(2, (i) {
          final labels = ['FEED', 'DISCOVER'];
          final isActive = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Feed tab ─────────────────────────────────────────
  Widget _feedTab() {
    final asyncFeed = ref.watch(socialFeedProvider);
    final asyncFriends = ref.watch(liveFriendsProvider);

    return asyncFeed.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load feed',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
      ),
      data: (posts) => ListView.builder(
        key: const ValueKey('feed'),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        itemCount: posts.length + 1, // +1 for friends strip at top
        itemBuilder: (context, i) {
          if (i == 0) {
            // Live friends strip
            return asyncFriends.when(
              data: (friends) => LiveFriendsStrip(friends: friends)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0, duration: 400.ms),
              loading: () => const SizedBox(height: 70),
              error: (_, __) => const SizedBox.shrink(),
            );
          }

          final post = posts[i - 1];
          return FeedPostCard(
            post: post,
            onCommentTap: () => CommentSheet.show(context, post.id),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 100 + i * 60),
                duration: 400.ms,
              )
              .slideY(
                begin: 0.06,
                end: 0,
                delay: Duration(milliseconds: 100 + i * 60),
                duration: 400.ms,
              );
        },
      ),
    );
  }

  // ── Discover tab ─────────────────────────────────────
  Widget _discoverTab() {
    final asyncUsers = ref.watch(discoverUsersProvider);

    return asyncUsers.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load suggestions',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
      ),
      data: (users) => SingleChildScrollView(
        key: const ValueKey('discover'),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: DiscoverGrid(users: users)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms),
      ),
    );
  }
}
