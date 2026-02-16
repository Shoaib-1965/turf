import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/map/screens/home_screen.dart';
import '../features/run_tracking/screens/active_run_screen.dart';
import '../features/run_tracking/screens/run_summary_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/competitions/screens/competitions_screen.dart';
import '../features/training_plans/screens/training_plans_screen.dart';
import '../features/social/screens/social_feed_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import 'app.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  debugLogDiagnostics: true,
  routes: [
    // ── Shell: persistent bottom nav ───────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // 0 — Map (Home)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // 1 — Leaderboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/leaderboard',
              name: 'leaderboard',
              builder: (context, state) => const LeaderboardScreen(),
            ),
          ],
        ),

        // 2 — Competitions
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/competitions',
              name: 'competitions',
              builder: (context, state) => const CompetitionsScreen(),
            ),
          ],
        ),

        // 3 — Social
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/social',
              name: 'social',
              builder: (context, state) => const SocialFeedScreen(),
            ),
          ],
        ),

        // 4 — Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: ':userId',
                  name: 'profileUser',
                  builder: (context, state) {
                    final userId = state.pathParameters['userId'] ?? '';
                    return ProfileScreen(userId: userId);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── Full-screen routes (no bottom nav) ─────────────
    GoRoute(
      path: '/run/active',
      name: 'activeRun',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ActiveRunScreen(),
    ),
    GoRoute(
      path: '/run/summary/:runId',
      name: 'runSummary',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final runId = state.pathParameters['runId'] ?? '';
        return RunSummaryScreen(runId: runId);
      },
    ),
    GoRoute(
      path: '/training',
      name: 'training',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TrainingPlansScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
