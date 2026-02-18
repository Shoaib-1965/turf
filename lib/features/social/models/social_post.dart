/// Type of social post.
enum SocialPostType { run, territoryMilestone, achievement }

/// A single social feed post.
class SocialPost {
  final String id;
  final String userId;
  final String username;
  final String photoUrl;
  final SocialPostType type;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isFollowing;

  // Run-specific
  final double? distanceKm;
  final String? duration;
  final String? pace;
  final double? territoryKm2;

  // General
  final String? caption;

  // Achievement-specific
  final String? badgeEmoji;
  final String? badgeName;
  final String? badgeDescription;

  // Territory-milestone-specific
  final double? totalTerritory;

  const SocialPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.type,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isFollowing = true,
    this.distanceKm,
    this.duration,
    this.pace,
    this.territoryKm2,
    this.caption,
    this.badgeEmoji,
    this.badgeName,
    this.badgeDescription,
    this.totalTerritory,
  });

  /// Human-readable time-ago string.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// A live-running friend.
class LiveFriend {
  final String userId;
  final String username;
  final String photoUrl;
  final double currentDistanceKm;

  const LiveFriend({
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.currentDistanceKm,
  });
}

/// Suggested user for discover tab.
class SuggestedUser {
  final String userId;
  final String username;
  final String photoUrl;
  final double territoryKm2;
  final int mutualFriends;

  const SuggestedUser({
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.territoryKm2,
    this.mutualFriends = 0,
  });
}
