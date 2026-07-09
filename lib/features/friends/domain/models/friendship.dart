import 'package:turf_app/features/profile/domain/models/profile.dart';

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final String status; // 'pending', 'accepted', 'blocked'
  final DateTime createdAt;
  
  // Optional populated profiles
  final Profile? requesterProfile;
  final Profile? addresseeProfile;

  Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.requesterProfile,
    this.addresseeProfile,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      requesterProfile: json['requester'] != null
          ? Profile.fromJson(json['requester'] as Map<String, dynamic>)
          : null,
      addresseeProfile: json['addressee'] != null
          ? Profile.fromJson(json['addressee'] as Map<String, dynamic>)
          : null,
    );
  }
}
