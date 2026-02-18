import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Settings state ───────────────────────────────────────
class SettingsState {
  // Connected apps
  final bool stravaConnected;
  final bool appleHealthConnected;
  final bool googleFitConnected;

  // Map prefs
  final String mapStyle; // 'Light' | 'Satellite' | 'Terrain'
  final double territoryOpacity; // 0..1
  final bool showFriendsTerritory;
  final bool showEnemyTerritory;
  final bool useKm; // true = km, false = miles

  // Notifications
  final bool notifyTerritoryStolen;
  final bool notifyFriendActivity;
  final bool notifyCompetitionUpdates;
  final bool notifyWeeklySummary;
  final bool notifyTrainingReminders;

  // Privacy
  final bool hideTerritory;
  final bool privateProfile;
  final bool hideFromLeaderboard;

  const SettingsState({
    this.stravaConnected = false,
    this.appleHealthConnected = false,
    this.googleFitConnected = false,
    this.mapStyle = 'Light',
    this.territoryOpacity = 0.35,
    this.showFriendsTerritory = true,
    this.showEnemyTerritory = true,
    this.useKm = true,
    this.notifyTerritoryStolen = true,
    this.notifyFriendActivity = true,
    this.notifyCompetitionUpdates = true,
    this.notifyWeeklySummary = true,
    this.notifyTrainingReminders = false,
    this.hideTerritory = false,
    this.privateProfile = false,
    this.hideFromLeaderboard = false,
  });

  SettingsState copyWith({
    bool? stravaConnected,
    bool? appleHealthConnected,
    bool? googleFitConnected,
    String? mapStyle,
    double? territoryOpacity,
    bool? showFriendsTerritory,
    bool? showEnemyTerritory,
    bool? useKm,
    bool? notifyTerritoryStolen,
    bool? notifyFriendActivity,
    bool? notifyCompetitionUpdates,
    bool? notifyWeeklySummary,
    bool? notifyTrainingReminders,
    bool? hideTerritory,
    bool? privateProfile,
    bool? hideFromLeaderboard,
  }) {
    return SettingsState(
      stravaConnected: stravaConnected ?? this.stravaConnected,
      appleHealthConnected: appleHealthConnected ?? this.appleHealthConnected,
      googleFitConnected: googleFitConnected ?? this.googleFitConnected,
      mapStyle: mapStyle ?? this.mapStyle,
      territoryOpacity: territoryOpacity ?? this.territoryOpacity,
      showFriendsTerritory: showFriendsTerritory ?? this.showFriendsTerritory,
      showEnemyTerritory: showEnemyTerritory ?? this.showEnemyTerritory,
      useKm: useKm ?? this.useKm,
      notifyTerritoryStolen:
          notifyTerritoryStolen ?? this.notifyTerritoryStolen,
      notifyFriendActivity: notifyFriendActivity ?? this.notifyFriendActivity,
      notifyCompetitionUpdates:
          notifyCompetitionUpdates ?? this.notifyCompetitionUpdates,
      notifyWeeklySummary: notifyWeeklySummary ?? this.notifyWeeklySummary,
      notifyTrainingReminders:
          notifyTrainingReminders ?? this.notifyTrainingReminders,
      hideTerritory: hideTerritory ?? this.hideTerritory,
      privateProfile: privateProfile ?? this.privateProfile,
      hideFromLeaderboard: hideFromLeaderboard ?? this.hideFromLeaderboard,
    );
  }
}

// ── Settings notifier ────────────────────────────────────
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      stravaConnected: prefs.getBool('stravaConnected') ?? false,
      appleHealthConnected: prefs.getBool('appleHealthConnected') ?? false,
      googleFitConnected: prefs.getBool('googleFitConnected') ?? false,
      mapStyle: prefs.getString('mapStyle') ?? 'Light',
      territoryOpacity: prefs.getDouble('territoryOpacity') ?? 0.35,
      showFriendsTerritory: prefs.getBool('showFriendsTerritory') ?? true,
      showEnemyTerritory: prefs.getBool('showEnemyTerritory') ?? true,
      useKm: prefs.getBool('useKm') ?? true,
      notifyTerritoryStolen: prefs.getBool('notifyTerritoryStolen') ?? true,
      notifyFriendActivity: prefs.getBool('notifyFriendActivity') ?? true,
      notifyCompetitionUpdates:
          prefs.getBool('notifyCompetitionUpdates') ?? true,
      notifyWeeklySummary: prefs.getBool('notifyWeeklySummary') ?? true,
      notifyTrainingReminders:
          prefs.getBool('notifyTrainingReminders') ?? false,
      hideTerritory: prefs.getBool('hideTerritory') ?? false,
      privateProfile: prefs.getBool('privateProfile') ?? false,
      hideFromLeaderboard: prefs.getBool('hideFromLeaderboard') ?? false,
    );
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void setStrava(bool v) {
    state = state.copyWith(stravaConnected: v);
    _save('stravaConnected', v);
  }

  void setAppleHealth(bool v) {
    state = state.copyWith(appleHealthConnected: v);
    _save('appleHealthConnected', v);
  }

  void setGoogleFit(bool v) {
    state = state.copyWith(googleFitConnected: v);
    _save('googleFitConnected', v);
  }

  void setMapStyle(String v) {
    state = state.copyWith(mapStyle: v);
    _save('mapStyle', v);
  }

  void setTerritoryOpacity(double v) {
    state = state.copyWith(territoryOpacity: v);
    _save('territoryOpacity', v);
  }

  void setShowFriends(bool v) {
    state = state.copyWith(showFriendsTerritory: v);
    _save('showFriendsTerritory', v);
  }

  void setShowEnemy(bool v) {
    state = state.copyWith(showEnemyTerritory: v);
    _save('showEnemyTerritory', v);
  }

  void setUseKm(bool v) {
    state = state.copyWith(useKm: v);
    _save('useKm', v);
  }

  void setNotifyTerritoryStolen(bool v) {
    state = state.copyWith(notifyTerritoryStolen: v);
    _save('notifyTerritoryStolen', v);
  }

  void setNotifyFriendActivity(bool v) {
    state = state.copyWith(notifyFriendActivity: v);
    _save('notifyFriendActivity', v);
  }

  void setNotifyCompetitionUpdates(bool v) {
    state = state.copyWith(notifyCompetitionUpdates: v);
    _save('notifyCompetitionUpdates', v);
  }

  void setNotifyWeeklySummary(bool v) {
    state = state.copyWith(notifyWeeklySummary: v);
    _save('notifyWeeklySummary', v);
  }

  void setNotifyTrainingReminders(bool v) {
    state = state.copyWith(notifyTrainingReminders: v);
    _save('notifyTrainingReminders', v);
  }

  void setHideTerritory(bool v) {
    state = state.copyWith(hideTerritory: v);
    _save('hideTerritory', v);
  }

  void setPrivateProfile(bool v) {
    state = state.copyWith(privateProfile: v);
    _save('privateProfile', v);
  }

  void setHideFromLeaderboard(bool v) {
    state = state.copyWith(hideFromLeaderboard: v);
    _save('hideFromLeaderboard', v);
  }
}

// ── Provider ─────────────────────────────────────────────
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
