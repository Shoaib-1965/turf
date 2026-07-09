import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:turf_app/features/notifications/presentation/providers/notification_provider.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home/activity');
        break;
      case 1:
        context.go('/home/friends');
        break;
      case 2:
        context.go('/home/map');
        break;
      case 3:
        context.go('/home/leaderboard');
        break;
      case 4:
        context.go('/home/profile');
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home/activity')) return 0;
    if (location.startsWith('/home/friends')) return 1;
    if (location.startsWith('/home/map')) return 2;
    if (location.startsWith('/home/leaderboard')) return 3;
    if (location.startsWith('/home/profile')) return 4;
    return 2; // Default to map
  }

  BottomNavigationBarItem _buildTabItem(IconData inactiveIcon, IconData activeIcon, String label, {int badgeCount = 0}) {
    Widget normalIcon = Icon(inactiveIcon, size: 24, color: const Color(0xFF8E8E93));
    Widget activeIconWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(activeIcon, size: 24, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );

    if (badgeCount > 0) {
      normalIcon = Badge(
        isLabelVisible: true,
        label: Text(badgeCount.toString()),
        backgroundColor: const Color(0xFFFF453A),
        child: normalIcon,
      );
      activeIconWidget = Badge(
        isLabelVisible: true,
        label: Text(badgeCount.toString()),
        backgroundColor: const Color(0xFFFF453A),
        child: activeIconWidget,
      );
    }

    return BottomNavigationBarItem(
      icon: normalIcon,
      activeIcon: activeIconWidget,
      label: label,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _calculateSelectedIndex(context);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A0A0A), // Dark theme background
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          _buildTabItem(Icons.bolt_outlined, Icons.bolt, 'Activity'),
          _buildTabItem(Iconsax.people, Iconsax.people5, 'Friends & Clubs'),
          BottomNavigationBarItem(
            icon: Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 30),
              ),
            ),
            label: 'Map',
          ),
          _buildTabItem(Icons.emoji_events_outlined, Icons.emoji_events, 'Leaderboard'),
          _buildTabItem(Icons.person_outline, Icons.person, 'Profile', badgeCount: unreadCount),
        ],
      ),
    );
  }
}
