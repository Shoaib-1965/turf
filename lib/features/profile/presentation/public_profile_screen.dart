import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:turf_app/features/profile/domain/models/profile.dart';
import 'package:turf_app/features/friends/presentation/providers/friends_provider.dart';

/// Provider to check friendship status for a given user ID
final friendshipStatusProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  return ref.read(socialRepositoryProvider).checkFriendshipStatus(userId);
});

class PublicProfileScreen extends ConsumerWidget {
  final Profile profile;

  const PublicProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(friendshipStatusProvider(profile.id));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          profile.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF1C1C1E),
                backgroundImage: profile.avatarUrl != null
                    ? CachedNetworkImageProvider(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white54)
                    : null,
              ),
              const SizedBox(height: 16),

              // Name and Level
              Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFF00E676), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${profile.level}',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              if (profile.lastActive != null)
                Text(
                  'Active ${timeago.format(profile.lastActive!)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),

              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],

              const SizedBox(height: 24),

              // Dynamic Friend Action Button
              SizedBox(
                width: double.infinity,
                child: statusAsync.when(
                  loading: () => const Center(
                    child: SizedBox(
                      height: 48,
                      child: CircularProgressIndicator(
                        color: Color(0xFF00E676),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (_, _) => _buildFriendButton(
                    context,
                    ref,
                    label: 'ADD FRIEND',
                    icon: Icons.person_add,
                    bgColor: const Color(0xFF00E676),
                    fgColor: Colors.black,
                    onTap: () => _sendRequest(context, ref),
                  ),
                  data: (status) {
                    switch (status) {
                      case 'you':
                        return const SizedBox.shrink(); // Don't show button on own profile
                      case 'accepted':
                        return _buildFriendButton(
                          context,
                          ref,
                          label: 'FRIENDS ✓',
                          icon: Icons.people,
                          bgColor: const Color(0xFF00E676).withOpacity(0.15),
                          fgColor: const Color(0xFF00E676),
                          borderColor: const Color(0xFF00E676),
                          onTap: () => _showUnfriendDialog(context, ref),
                        );
                      case 'pending_sent':
                        return _buildFriendButton(
                          context,
                          ref,
                          label: 'REQUEST SENT',
                          icon: Icons.hourglass_top,
                          bgColor: const Color(0xFF2C2C2E),
                          fgColor: Colors.white54,
                        );
                      case 'pending_received':
                        return Row(
                          children: [
                            Expanded(
                              child: _buildFriendButton(
                                context,
                                ref,
                                label: 'ACCEPT',
                                icon: Icons.check,
                                bgColor: const Color(0xFF00E676),
                                fgColor: Colors.black,
                                onTap: () =>
                                    _acceptReceivedRequest(context, ref),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildFriendButton(
                              context,
                              ref,
                              label: 'DECLINE',
                              icon: Icons.close,
                              bgColor: const Color(
                                0xFFFF453A,
                              ).withOpacity(0.15),
                              fgColor: const Color(0xFFFF453A),
                              onTap: () =>
                                  _declineReceivedRequest(context, ref),
                            ),
                          ],
                        );
                      default: // 'none'
                        return _buildFriendButton(
                          context,
                          ref,
                          label: 'ADD FRIEND',
                          icon: Icons.person_add,
                          bgColor: const Color(0xFF00E676),
                          fgColor: Colors.black,
                          onTap: () => _sendRequest(context, ref),
                        );
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Distance',
                      value: '${profile.totalDistanceKm.toStringAsFixed(1)} km',
                      icon: Icons.route,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Total XP',
                      value: '${profile.totalXp}',
                      icon: Icons.star,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Streak',
                      value: '${profile.streakDays} days',
                      icon: Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Land Claimed',
                      value: _formatArea(profile.totalAreaClaimedSqm),
                      icon: Icons.flag,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: fgColor, size: 20),
      label: Text(
        label,
        style: TextStyle(color: fgColor, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: borderColor != null
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
    );
  }

  void _sendRequest(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(socialRepositoryProvider)
          .sendFriendRequest(profile.id);
      ref.invalidate(friendshipStatusProvider(profile.id));
      if (context.mounted) {
        if (result == 'sent') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request sent!'),
              backgroundColor: Color(0xFF00E676),
            ),
          );
        } else if (result == 'already_pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request already pending'),
              backgroundColor: Color(0xFFFF9100),
            ),
          );
        } else if (result == 'already_friends') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already friends!'),
              backgroundColor: Color(0xFF00B0FF),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send request'),
            backgroundColor: Color(0xFFFF453A),
          ),
        );
      }
    }
  }

  void _acceptReceivedRequest(BuildContext context, WidgetRef ref) async {
    try {
      // We need the friendship ID. Fetch it.
      final repo = ref.read(socialRepositoryProvider);
      final pending = await repo.getPendingRequests();
      final match = pending
          .where((f) => f.requesterId == profile.id)
          .firstOrNull;
      if (match != null) {
        await repo.respondToRequest(match.id, true);
        ref.invalidate(friendshipStatusProvider(profile.id));
        ref.invalidate(friendsProvider);
        ref.invalidate(pendingRequestsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request accepted!'),
              backgroundColor: Color(0xFF00E676),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error accepting request'),
            backgroundColor: Color(0xFFFF453A),
          ),
        );
      }
    }
  }

  void _declineReceivedRequest(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      final pending = await repo.getPendingRequests();
      final match = pending
          .where((f) => f.requesterId == profile.id)
          .firstOrNull;
      if (match != null) {
        await repo.respondToRequest(match.id, false);
        ref.invalidate(friendshipStatusProvider(profile.id));
        ref.invalidate(pendingRequestsProvider);
      }
    } catch (_) {}
  }

  void _showUnfriendDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unfriend?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${profile.fullName} from your friends?',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(socialRepositoryProvider)
                  .deleteFriendship(profile.id);
              ref.invalidate(friendshipStatusProvider(profile.id));
              ref.invalidate(friendsProvider);
            },
            child: const Text(
              'Unfriend',
              style: TextStyle(color: Color(0xFFFF453A)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatArea(double sqm) {
    if (sqm < 1) return '0 m²';
    if (sqm < 10000) {
      return '${sqm.round()} m²';
    }
    return '${(sqm / 10000).toStringAsFixed(1)} ha';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Space Grotesk',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
