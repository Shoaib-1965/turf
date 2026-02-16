import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'router.dart';
import '../shared/widgets/glass_bottom_nav.dart';

/// Root application widget.
class TurfApp extends StatelessWidget {
  const TurfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TURF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

/// Main shell that wraps the bottom-nav tabs.
/// Persists the [GlassBottomNavBar] across Map, Leaderboard,
/// Competitions, Social, and Profile screens.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Page content ─────────────────────────────
          navigationShell,

          // ── Floating bottom nav ──────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
