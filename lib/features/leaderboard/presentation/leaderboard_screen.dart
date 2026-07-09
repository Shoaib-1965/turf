import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:turf_app/features/leaderboard/domain/models/leaderboard_entry.dart';
import 'package:turf_app/features/leaderboard/presentation/providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with TickerProviderStateMixin {
  late TabController _scopeTabController;
  final List<Map<String, String>> _types = [
    {'id': 'weekly_distance', 'label': 'Weekly Distance'},
    {'id': 'monthly_distance', 'label': 'Monthly Distance'},
    {'id': 'territory_count', 'label': 'Territory Count'},
    {'id': 'total_xp', 'label': 'Total XP'},
    {'id': 'streak', 'label': 'Streak'},
  ];

  late RealtimeChannel _subscription;

  @override
  void initState() {
    super.initState();
    _scopeTabController = TabController(length: 2, vsync: this);
    _scopeTabController.addListener(() {
      if (!_scopeTabController.indexIsChanging) {
        ref.read(leaderboardScopeProvider.notifier).state = _scopeTabController.index == 0 ? 'global' : 'friends';
      }
    });

    // Realtime subscription to animate changes
    _subscription = Supabase.instance.client
        .channel('public:leaderboard_entries')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_entries',
          callback: (payload) {
            // Trigger a refresh on any change to the leaderboard table
            ref.invalidate(leaderboardProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _scopeTabController.dispose();
    _subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentType = ref.watch(leaderboardTypeProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: InkWell(
              onTap: () => context.push('/home/challenges'),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🏆 Challenges',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _scopeTabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs (Horizontal Scroll)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = currentType == type['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type['label']!),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00E676).withOpacity(0.2),
                    backgroundColor: const Color(0xFF1C1C1E),
                    labelStyle: TextStyle(color: isSelected ? const Color(0xFF00E676) : Colors.white54, fontWeight: FontWeight.bold),
                    side: BorderSide(color: isSelected ? const Color(0xFF00E676) : Colors.transparent),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(leaderboardTypeProvider.notifier).state = type['id']!;
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Leaderboard List
          Expanded(
            child: _LeaderboardContent(),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      loading: () => const _LeaderboardSkeleton(),
      error: (e, _) => Center(child: Text('Error loading leaderboard', style: const TextStyle(color: Colors.red))),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text("No entries found.", style: TextStyle(color: Colors.white54)));
        }

        final top3 = entries.take(3).toList();
        final rest = entries.skip(3).toList();

        final currentUserId = Supabase.instance.client.auth.currentUser!.id;
        final isUserInList = entries.any((e) => e.userId == currentUserId);

        return Stack(
          children: [
            RefreshIndicator(
              color: const Color(0xFF00E676),
              backgroundColor: const Color(0xFF1C1C1E),
              onRefresh: () => ref.refresh(leaderboardProvider.future),
              child: CustomScrollView(
                slivers: [
                  if (top3.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Podium(top3: top3),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = rest[index];
                        return _AnimatedLeaderboardRow(
                          key: ValueKey(entry.userId),
                          entry: entry,
                          index: index,
                          child: _LeaderboardRow(entry: entry),
                        );
                      },
                      childCount: rest.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for bottom card
                ],
              ),
            ),
            if (!isUserInList)
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _CurrentUserPinnedCard(),
              ),
          ],
        );
      },
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;

  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    // Determine max value for relative height, but we use fixed heights for UI consistency
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _PodiumItem(entry: top3[1], rank: 2, height: 120, color: const Color(0xFFC0C0C0)), // Silver
          if (top3.isNotEmpty) _PodiumItem(entry: top3[0], rank: 1, height: 160, color: const Color(0xFFFFD700)), // Gold
          if (top3.length > 2) _PodiumItem(entry: top3[2], rank: 3, height: 100, color: const Color(0xFFCD7F32)), // Bronze
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color color;

  const _PodiumItem({required this.entry, required this.rank, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (rank * 200)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showProfilePopup(context, entry.userId, entry.rank);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
                ),
                child: CircleAvatar(
                  radius: rank == 1 ? 40 : 30,
                  backgroundColor: const Color(0xFF1C1C1E),
                  backgroundImage: entry.profile?.avatarUrl != null ? CachedNetworkImageProvider(entry.profile!.avatarUrl!) : null,
                  child: entry.profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text('$rank', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(top: BorderSide(color: color, width: 4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.profile?.username ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatValue(entry.value, entry.leaderboardType),
                  style: const TextStyle(color: Colors.white, fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isMe = entry.userId == currentUserId;
    
    final isTop10 = entry.rank <= 10;
    final rankColor = isMe 
        ? const Color(0xFF00E676) 
        : (isTop10 ? const Color(0xFF00E676) : const Color(0xFF3A3A3C));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showProfilePopup(context, entry.userId, entry.rank);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isMe ? const Color(0xFF00E676).withOpacity(0.1) : const Color(0xFF242424),
            isMe ? const Color(0xFF00E676).withOpacity(0.05) : const Color(0xFF1C1C1E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: rankColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: isMe ? const Color(0xFF00E676) : Colors.white54,
                fontWeight: FontWeight.bold,
                fontFamily: 'Space Grotesk',
                fontSize: 16,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF141414),
              backgroundImage: entry.profile?.avatarUrl != null ? CachedNetworkImageProvider(entry.profile!.avatarUrl!) : null,
              child: entry.profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54, size: 20) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.profile?.username ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Lvl ${entry.profile?.level ?? 1}',
                  style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            _formatValue(entry.value, entry.leaderboardType),
            style: const TextStyle(
              color: Colors.white, 
              fontFamily: 'Space Grotesk', 
              fontWeight: FontWeight.bold, 
              fontSize: 18,
            ),
          ),
        ],
      ),
    ),
  );
  }
}

String _formatValue(double value, String type) {
  if (type.contains('distance')) return '${value.toStringAsFixed(1)} km';
  if (type == 'total_xp') return '${value.toInt()} XP';
  if (type == 'streak') return '${value.toInt()} days';
  return value.toInt().toString();
}

class _CurrentUserPinnedCard extends ConsumerWidget {
  const _CurrentUserPinnedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(currentUserLeaderboardEntryProvider);
    
    return entryAsync.when(
      data: (entry) {
        if (entry == null) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: const Border(top: BorderSide(color: Color(0xFF00E676), width: 1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: _LeaderboardRow(entry: entry),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _AnimatedLeaderboardRow extends StatefulWidget {
  final LeaderboardEntry entry;
  final int index;
  final Widget child;

  const _AnimatedLeaderboardRow({required Key key, required this.entry, required this.index, required this.child}) : super(key: key);

  @override
  State<_AnimatedLeaderboardRow> createState() => _AnimatedLeaderboardRowState();
}

class _AnimatedLeaderboardRowState extends State<_AnimatedLeaderboardRow> with SingleTickerProviderStateMixin {
  int? _previousRank;
  late AnimationController _controller;
  late Animation<Color?> _flashColorAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isEntrance = true;

  @override
  void initState() {
    super.initState();
    _previousRank = widget.entry.rank;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flashColorAnimation = const AlwaysStoppedAnimation(Colors.transparent);
    
    // Entrance animation setup
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );

    // Staggered entrance
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _controller.forward(from: 0.0).then((_) {
          if (mounted) setState(() => _isEntrance = false);
        });
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedLeaderboardRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.rank != widget.entry.rank) {
      final oldRank = _previousRank ?? widget.entry.rank;
      _previousRank = widget.entry.rank;
      
      final movedUp = widget.entry.rank < oldRank;
      final baseColor = movedUp ? const Color(0xFF00E676).withOpacity(0.3) : const Color(0xFFFF453A).withOpacity(0.3);
      
      _isEntrance = false;
      _flashColorAnimation = ColorTween(begin: baseColor, end: Colors.transparent).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut)
      );

      final yOffset = (oldRank - widget.entry.rank) * 70.0;
      _slideAnimation = Tween<double>(begin: yOffset, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.66, curve: Curves.easeInOut))
      );
      
      _fadeAnimation = const AlwaysStoppedAnimation(1.0);

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                color: _flashColorAnimation.value,
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1C1C1E),
      highlightColor: const Color(0xFF2C2C2E),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _SkeletonPodiumItem(height: 120),
                  _SkeletonPodiumItem(height: 160),
                  _SkeletonPodiumItem(height: 100),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1C1C1E)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Container(width: 100, height: 14, color: Colors.white),
                      const Spacer(),
                      Container(width: 60, height: 14, color: Colors.white),
                    ],
                  ),
                );
              },
              childCount: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPodiumItem extends StatelessWidget {
  final double height;
  const _SkeletonPodiumItem({required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 60, height: 12, color: Colors.black),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showProfilePopup(BuildContext context, String userId, int rank) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _ProfilePopupContent(userId: userId, rank: rank);
    },
  );
}

class _ProfilePopupContent extends StatefulWidget {
  final String userId;
  final int rank;
  const _ProfilePopupContent({required this.userId, required this.rank});

  @override
  State<_ProfilePopupContent> createState() => _ProfilePopupContentState();
}

class _ProfilePopupContentState extends State<_ProfilePopupContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _friendshipData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser!.id;

    try {
      final profile = await client
          .from('profiles')
          .select('*, user_badges(*, badges(name, icon_url)), territories:territories(count)')
          .eq('id', widget.userId)
          .single();

      Map<String, dynamic>? friendship;
      if (currentUserId != widget.userId) {
        friendship = await client
            .from('friendships')
            .select()
            .or('and(requester_id.eq.$currentUserId,addressee_id.eq.${widget.userId}),and(requester_id.eq.${widget.userId},addressee_id.eq.$currentUserId)')
            .maybeSingle();
      }

      if (mounted) {
        setState(() {
          _profileData = profile;
          _friendshipData = friendship;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load profile')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      );
    }

    final profile = _profileData!;
    final isMe = Supabase.instance.client.auth.currentUser!.id == widget.userId;
    final terraColor = profile['terra_color'] != null 
        ? Color(int.parse(profile['terra_color'].toString().replaceFirst('#', '0xFF'))) 
        : const Color(0xFF00E676);

    String friendStatus = 'Add Friend';
    if (_friendshipData != null) {
      if (_friendshipData!['status'] == 'accepted') {
        friendStatus = 'Friends';
      } else if (_friendshipData!['status'] == 'pending') friendStatus = 'Pending';
    }

    final totalKm = ((profile['total_distance_m'] ?? 0) / 1000).toStringAsFixed(1);
    final totalXp = (profile['total_xp'] ?? 0).toString();
    final zones = (profile['territories'] != null && (profile['territories'] as List).isNotEmpty)
        ? (profile['territories'][0]['count'] ?? 0).toString() 
        : '0';
    final level = (profile['level'] ?? 1).toString();
    final badges = (profile['user_badges'] as List?) ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFF3A3A3C), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),

          // Header
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: terraColor, width: 3),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF2C2C2E),
              backgroundImage: profile['avatar_url'] != null ? CachedNetworkImageProvider(profile['avatar_url']) : null,
              child: profile['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white, size: 36) : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile['username'] ?? 'Unknown',
            style: const TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: terraColor, borderRadius: BorderRadius.circular(12)),
            child: Text('LVL $level', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
          if (profile['bio'] != null && profile['bio'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile['bio'],
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF8E8E93)),
            ),
          ],
          const SizedBox(height: 32),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(value: totalKm, unit: 'km', label: 'Distance'),
              _StatItem(value: totalXp, unit: '', label: 'XP'),
              _StatItem(value: zones, unit: '', label: 'Zones'),
              _StatItem(value: level, unit: '', label: 'Level'),
            ],
          ),
          const SizedBox(height: 32),

          // Ranking
          Column(
            children: [
              const Text('LEADERBOARD RANK', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('#${widget.rank}', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, fontSize: 36, color: terraColor)),
            ],
          ),
          const SizedBox(height: 32),

          // Badges
          if (badges.isNotEmpty) ...[
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(badges.length, 5),
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final b = badges[index]['badges'];
                  return Column(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2C2C2E)),
                        child: b?['icon_url'] != null ? CachedNetworkImage(imageUrl: b!['icon_url']) : const Icon(Icons.stars, color: Colors.amber),
                      ),
                      const SizedBox(height: 4),
                      Text(b?['name'] ?? 'Badge', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 10)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // context.push('/profile/${widget.userId}'); // Routing can be enabled if the route exists
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('View Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF3A3A3C)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(friendStatus),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _StatItem({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            if (unit.isNotEmpty) Text(' $unit', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 10)),
      ],
    );
  }
}
