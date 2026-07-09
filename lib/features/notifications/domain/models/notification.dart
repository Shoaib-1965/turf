class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.metadata = const {},
    required this.isRead,
    required this.createdAt,
  });

  /// Helper to extract a related ID from metadata
  String? get relatedId {
    if (metadata.containsKey('friendship_id')) return metadata['friendship_id'] as String?;
    if (metadata.containsKey('club_id')) return metadata['club_id'] as String?;
    if (metadata.containsKey('challenge_id')) return metadata['challenge_id'] as String?;
    return null;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
