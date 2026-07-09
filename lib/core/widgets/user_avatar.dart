import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? fullName;
  final String? terraColor;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.fullName,
    this.terraColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => _initialCircle(),
        errorWidget: (context, url, error) => _initialCircle(),
        memCacheWidth: 200,
        memCacheHeight: 200,
      );
    }
    return _initialCircle();
  }

  Widget _initialCircle() {
    final color = terraColor != null 
        ? Color(int.parse(terraColor!.replaceAll('#', '0xFF'))) 
        : const Color(0xFF00E676);
    final initial = (fullName?.isNotEmpty == true ? fullName![0] : '?').toUpperCase();
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initial, 
        style: TextStyle(
          color: Colors.black, 
          fontWeight: FontWeight.bold, 
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
