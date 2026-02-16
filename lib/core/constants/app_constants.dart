class AppConstants {
  AppConstants._();

  // ── App Identity ─────────────────────────────────────
  static const String appName = 'TURF';
  static const String tagline = 'Run the streets. Own the turf.';

  // ── Map Defaults ─────────────────────────────────────
  static const double defaultZoom = 15.0;
  static const double defaultLat = 0.0;
  static const double defaultLng = 0.0;
  static const double maxZoom = 19.0;
  static const double minZoom = 3.0;

  // ── Territory Grid ───────────────────────────────────
  static const double gridCellSizeMeters = 50.0;
  static const int minRunDurationSeconds = 60;
  static const double minRunDistanceMeters = 100.0;
  static const double captureRadiusMeters = 25.0;

  // ── Animation Durations ──────────────────────────────
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // ── Leaderboard ──────────────────────────────────────
  static const int leaderboardPageSize = 20;
  static const int maxRecentRuns = 50;

  // ── Run Tracking ─────────────────────────────────────
  static const int locationUpdateIntervalMs = 1000;
  static const double minLocationAccuracyMeters = 20.0;
  static const double minMovementMeters = 5.0;
}
