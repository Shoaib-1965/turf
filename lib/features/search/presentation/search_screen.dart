import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'package:turf_app/core/widgets/empty_state.dart';
import 'package:turf_app/core/widgets/user_avatar.dart';
import 'package:turf_app/features/friends/presentation/providers/friends_provider.dart';
import 'package:turf_app/features/profile/domain/models/profile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Profile> _userResults = [];
  List<dynamic> _territoryResults = [];

  bool _isLoading = false;

  // user_id -> 'none', 'pending_sent', 'pending_received', 'accepted', 'you'
  Map<String, String> _relationshipMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _userResults = [];
        _territoryResults = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(socialRepositoryProvider);
      final supabase = Supabase.instance.client;

      // Search Users via repository (searches username + full_name)
      final profiles = await repo.searchUsers(query);

      // Batch check relationship statuses
      final userIds = profiles.map((p) => p.id).toList();
      final relationships = await repo.batchCheckFriendshipStatus(userIds);

      // Search Territories
      final territories = await supabase
          .from('territories')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      if (mounted) {
        setState(() {
          _userResults = profiles;
          _relationshipMap = relationships;
          _territoryResults = territories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed. Try again.')),
        );
      }
    }
  }

  Future<void> _handleAddFriend(String userId) async {
    setState(() {
      _relationshipMap[userId] = 'pending_sent';
    });
    try {
      final result = await ref
          .read(socialRepositoryProvider)
          .sendFriendRequest(userId);
      if (result == 'already_friends') {
        setState(() => _relationshipMap[userId] = 'accepted');
      } else if (result == 'already_pending') {
        setState(() => _relationshipMap[userId] = 'pending_sent');
      }
      // 'sent' → already set to pending_sent
    } catch (e) {
      if (mounted) {
        setState(() {
          _relationshipMap[userId] = 'none'; // Revert on error
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send request')));
      }
    }
  }

  Widget _buildRelationshipButton(String userId) {
    final status = _relationshipMap[userId] ?? 'none';

    if (status == 'you') return const SizedBox.shrink();

    if (status == 'pending_sent') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    if (status == 'pending_received') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E676)),
        ),
        child: const Text(
          'Accept',
          style: TextStyle(
            color: Color(0xFF00E676),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00E676)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Friends',
          style: TextStyle(
            color: Color(0xFF00E676),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    // 'none'
    return GestureDetector(
      onTap: () => _handleAddFriend(userId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Add Friend',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF1C1C1E),
            highlightColor: const Color(0xFF2C2C2E),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search users or territories...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white54,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
            autofocus: true,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Territories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // USERS TAB
          _isLoading
              ? _buildShimmer()
              : _userResults.isEmpty && _searchController.text.isNotEmpty
              ? const Center(
                  child: Text(
                    'No users found.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : _userResults.isEmpty
              ? const EmptyState(
                  icon: Icons.person_search,
                  title: 'Search for runners near you',
                  subtitle: 'Type a name or username above.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _userResults.length,
                  itemBuilder: (context, index) {
                    final u = _userResults[index];
                    final isOnline =
                        u.lastActive != null &&
                        DateTime.now().difference(u.lastActive!).inMinutes < 15;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isOnline
                              ? Border.all(
                                  color: const Color(0xFF00E676),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: UserAvatar(
                          size: 48,
                          avatarUrl: u.avatarUrl,
                          fullName: u.fullName,
                          terraColor: u.terraColor,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            u.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LVL ${u.level}',
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Space Grotesk',
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${u.username}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${u.totalDistanceKm.toStringAsFixed(1)} km total',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                        ],
                      ),
                      trailing: _buildRelationshipButton(u.id),
                      onTap: () => context.push('/profile/${u.id}', extra: u),
                    );
                  },
                ),

          // TERRITORIES TAB
          _isLoading
              ? _buildShimmer()
              : _territoryResults.isEmpty && _searchController.text.isNotEmpty
              ? const Center(
                  child: Text(
                    'No territories found.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : _territoryResults.isEmpty
              ? const EmptyState(
                  icon: Icons.map,
                  title: 'Search for territories',
                  subtitle: 'Find zones to conquer.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _territoryResults.length,
                  itemBuilder: (context, index) {
                    final t = _territoryResults[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag, color: Color(0xFF00E676)),
                      ),
                      title: Text(
                        t['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Captured ${t['capture_count'] ?? 0} times',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      onTap: () => context.go('/home/map'),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
