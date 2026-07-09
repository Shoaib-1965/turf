# TURF — Phase Prompts: Skeleton Loading, Real Fitness Data & Page Fixes

---

# PHASE 1 — Skeleton Loading Screens
**→ Send to Antigravity**

```
Read README.md. Replace ALL CircularProgressIndicator loading states across these screens with beautiful skeleton loading screens that match the exact layout of the real content. Use the `shimmer` package (already in pubspec.yaml).

IMPORTANT RULE: Never show a CircularProgressIndicator anywhere in the app except during explicit one-time actions (like submitting a form). All list/feed/page loading must use skeletons.

---

SKELETON DESIGN SYSTEM — apply consistently:
- Shimmer base color: #1C1C1E
- Shimmer highlight color: #2C2C2E
- All skeleton shapes use border radius matching the real content
- Wrap all skeletons in: Shimmer.fromColors(baseColor: Color(0xFF1C1C1E), highlightColor: Color(0xFF2C2C2E), child: ...)

---

SCREEN 1 — Activity Feed Screen (lib/features/activity/presentation/activity_feed_screen.dart):

Show 4 skeleton activity cards while loading. Each skeleton card matches the real card layout:
- Full width card, #1C1C1E background, 12px radius, 16px padding, margin bottom 12px
- Row at top: circle (40px, for avatar) + rectangle (120px wide x 14px, for name) + small pill (60px x 20px, right-aligned, for activity badge)
- Large rectangle below: 200px wide x 44px (for distance number)
- Row of 3 small rectangles: each 80px x 12px (for pace/duration/calories)
- Rectangle: full width x 100px (for route map thumbnail)
- Row at bottom: 2 small rectangles (like/comment counts)

---

SCREEN 2 — Leaderboard Screen (lib/features/leaderboard/presentation/leaderboard_screen.dart):

Show skeleton for:
- TOP PODIUM: 3 skeleton boxes side by side (center taller). Each: circle 48px + rectangle 60px x 12px below
- LIST: 8 skeleton rows. Each row: small square (rank number placeholder, 32px) + circle 36px (avatar) + rectangle 100px x 14px (name) + rectangle 60px x 14px right-aligned (value)

---

SCREEN 3 — Friends Screen (lib/features/friends/presentation/friends_screen.dart):

Show 6 skeleton friend cards while loading. Each:
- Row: circle 48px (avatar) + column of 2 rectangles (name: 120px x 14px, subtitle: 80px x 11px) + pill 70px x 30px right-aligned (action button placeholder)
- Divider line below each card

---

SCREEN 4 — Clubs Screen (lib/features/clubs/presentation/clubs_list_screen.dart):

Show:
- Horizontal scroll row of 3 skeleton "My Clubs" cards: each 140px wide x 100px tall, rounded 12px
- Below: 4 skeleton vertical club list items matching club card layout

---

SCREEN 5 — Challenges Screen (lib/features/challenges/presentation/challenges_screen.dart):

Show 4 skeleton challenge cards. Each:
- Rectangle full width x 130px, 12px radius
- Inside: title placeholder (180px x 16px), type badge (80px x 22px), progress bar (full width x 8px, rounded), bottom row 2 small rectangles

---

SCREEN 6 — Goals Screen (lib/features/goals/presentation/goals_screen.dart):

Show 3 skeleton goal cards. Each:
- Rectangle full width x 90px, 12px radius
- Icon circle 40px left + title rectangle 140px x 14px + progress bar full width x 8px + percentage rectangle 40px x 12px

Apply skeletons consistently. Remove every CircularProgressIndicator from these 6 screens.
```

---

# PHASE 2 — Real Fitness Data Calculations During Live Activity
**→ Send to Antigravity**

```
Read README.md. Fix the live activity tracking screen (lib/features/activity/presentation/live_activity_screen.dart) to show 100% accurate, real-time calculated fitness data. No random or estimated values. All calculations must be based on real GPS data from geolocator.

---

ADD THIS PACKAGE to pubspec.yaml if not already present:
- `sensors_plus` (for device accelerometer — helps smooth GPS speed on Android)

---

REAL CALCULATION IMPLEMENTATIONS:

1. DISTANCE (already implemented — verify it uses Haversine):
Use geolocator's `Geolocator.distanceBetween(lat1, lng1, lat2, lng2)` between each consecutive GPS point pair. Sum all segments. This gives meters → divide by 1000 for km. This is the gold standard. Do NOT use GPS accuracy radius as distance.

2. SPEED (current, real-time):
- Use the `speed` property from geolocator's `Position` object directly: `position.speed` (in m/s)
- Convert to km/h: `position.speed * 3.6`
- Apply smoothing: keep a rolling buffer of last 5 speed readings, show the average to prevent erratic jumps from GPS noise: 
```dart
List<double> _speedBuffer = [];
double get smoothedSpeed {
  if (_speedBuffer.isEmpty) return 0;
  return _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;
}
```
- On each GPS update: add position.speed * 3.6 to buffer, remove oldest if buffer > 5

3. PACE (min/km):
- Only calculate pace when speed > 0.5 km/h (avoid division-by-zero or insane pace when standing still)
- Formula: `pace = 60 / speedKmh` → gives decimal minutes → convert to MM:SS format
```dart
String formatPace(double speedKmh) {
  if (speedKmh < 0.5) return '--:--';
  double paceDecimal = 60 / speedKmh;
  int minutes = paceDecimal.floor();
  int seconds = ((paceDecimal - minutes) * 60).round();
  return '${minutes.toString().padLeft(2,'0')}:${seconds.toString().padLeft(2,'0')}';
}
```

4. CALORIES BURNED (scientifically accurate using MET values):
Use the standard MET (Metabolic Equivalent of Task) formula:
- `calories = MET × weight_kg × duration_hours`
MET values per activity:
  - Running: if speed < 8 km/h → MET = 8.3, if 8-11 km/h → MET = 11.0, if > 11 km/h → MET = 14.5
  - Walking: if speed < 4 km/h → MET = 2.8, if 4-6 km/h → MET = 3.5, if > 6 km/h → MET = 4.3
  - Cycling: if speed < 16 km/h → MET = 6.0, if 16-20 km/h → MET = 8.0, if > 20 km/h → MET = 10.0

Weight: read from `profiles` table (`weight_kg` column — if column doesn't exist, add it via Supabase SQL: `alter table public.profiles add column if not exists weight_kg float4 default 70;`). Default to 70kg if null.

Calculate calories in real time: update every 10 seconds using elapsed time and current smoothed speed.

5. ELEVATION GAIN (real, using GPS altitude):
- Use `position.altitude` from geolocator's Position object
- Only count UPWARD changes: if `currentAltitude - lastAltitude > 0.5m` (threshold to filter noise) → add the difference to total elevation gain
- Never subtract negative changes from the gain total (elevation gain only goes up)
- Apply a 3-reading median filter on raw altitude readings to remove GPS altitude noise before calculating gain

6. AREA CLAIMED (m²):
- Already calculated by the loop detection algorithm — just display it live in the stats panel
- Format: if < 10000 → show as "X,XXX m²", if ≥ 10000 → show as "X.X ha" (hectares)

7. MAX SPEED:
- Track a `_maxSpeed` variable, update it whenever `smoothedSpeed > _maxSpeed`

---

DISPLAY in LiveActivityScreen stats panel:
Update all stat cells to show the above real values:
- PRIMARY: distance_km (Haversine sum)
- TIMER: elapsed seconds formatted as HH:MM:SS
- PACE: formatted MM:SS /km (or "--:--" when stationary)
- SPEED: smoothed km/h with 1 decimal place
- CALORIES: real MET-based calculation, shown as integer
- ELEVATION: cumulative gain in meters, 1 decimal place

---

ON ACTIVITY SAVE (when session ends):
Pass all real calculated values to activity_sessions insert:
- distance_km: Haversine total
- avg_speed_kmh: total_distance / total_time_hours
- max_speed_kmh: _maxSpeed variable
- calories_burned: final MET calculation
- elevation_gain_m: cumulative altitude gain
- duration_seconds: elapsed seconds

Also run this SQL in Supabase first:
`alter table public.profiles add column if not exists weight_kg float4 default 70;`
And add a weight input field in SettingsScreen so users can set their weight for accurate calorie calculation.
```

---

# PHASE 3 — Fix Challenges, Leaderboard & Goals Pages
**→ Send to Antigravity**

```
Read README.md and review the full database schema (all tables confirmed exist in Supabase). 

Do a complete audit and fix of these 3 screens. For each screen: check if data is loading from Supabase correctly, check if actions (join, create, complete) work end to end, check if real-time updates work, and fix anything broken.

---

CHALLENGES SCREEN AUDIT & FIX (lib/features/challenges/presentation/challenges_screen.dart):

Expected behavior — verify and fix each:

1. LOADING: Query `challenges` table where `is_public = true` AND `ends_at > now()` for Active tab. Join with `challenge_participants` to get current user's participation status and progress. If this query is missing or wrong, fix it.

2. JOIN CHALLENGE: Tapping "Join" → insert into `challenge_participants` (challenge_id, user_id, current_value: 0, completed: false). Button should immediately change to "Joined" / show progress. Verify this works.

3. PROGRESS TRACKING: When an activity session is saved (in activity_repository.dart), it should update `challenge_participants.current_value` for all active challenges the user is enrolled in, matching activity_type. Verify this logic exists and is correct. If not present, add it:
```dart
// After saving activity session, update challenge progress
final activeChallenges = await supabase
  .from('challenge_participants')
  .select('*, challenges(*)')
  .eq('user_id', userId)
  .eq('completed', false);

for (final participant in activeChallenges) {
  final challenge = participant['challenges'];
  if (challenge['ends_at'] != null && DateTime.parse(challenge['ends_at']).isBefore(DateTime.now())) continue;
  
  double newValue = participant['current_value'];
  
  switch (challenge['challenge_type']) {
    case 'distance': newValue += session.distanceKm; break;
    case 'elevation': newValue += session.elevationGainM ?? 0; break;
    case 'speed': newValue = max(newValue, session.maxSpeedKmh ?? 0); break;
  }
  
  final completed = newValue >= challenge['target_value'];
  
  await supabase.from('challenge_participants').update({
    'current_value': newValue,
    'completed': completed,
    'completed_at': completed ? DateTime.now().toIso8601String() : null,
  }).eq('id', participant['id']);
  
  if (completed) {
    // Award XP
    await supabase.rpc('award_xp', params: {'p_user_id': userId, 'p_xp': challenge['xp_reward']});
    // Insert notification
    await supabase.from('notifications').insert({
      'user_id': userId,
      'type': 'goal_completed',
      'title': 'Challenge Complete!',
      'body': 'You completed: ${challenge['title']}',
      'metadata': {'challenge_id': challenge['id']},
    });
  }
}
```

4. CREATE CHALLENGE: Verify CreateChallengeScreen inserts correctly into `challenges` table AND auto-inserts creator into `challenge_participants`. Fix if broken.

5. MY CHALLENGES TAB: Query challenge_participants joined with challenges where user_id = currentUser. Show progress bars based on current_value / target_value.

6. COMPLETED TAB: Query challenge_participants where user_id = currentUser AND completed = true. Show with checkmark and completed_at date.

---

LEADERBOARD SCREEN AUDIT & FIX (lib/features/leaderboard/presentation/leaderboard_screen.dart):

Expected behavior — verify and fix:

1. DATA SOURCE: Leaderboard reads from `leaderboard_entries` table. This table is populated by `public.update_leaderboard()` SQL function. The problem: this function is NOT being called automatically yet (no cron job set up). 

FIX — call update_leaderboard on leaderboard screen load:
```dart
// At the start of leaderboard data fetch, call the refresh function first
await supabase.rpc('update_leaderboard');
// Then fetch leaderboard_entries
```
This ensures fresh data every time someone opens the leaderboard. It's a small performance cost but acceptable for now.

2. FILTER TABS: Verify all 5 types work (weekly_distance, monthly_distance, territory_count, total_xp, streak). Each tab should query `leaderboard_entries` filtered by `leaderboard_type` and ordered by `rank ASC`.

3. FRIENDS FILTER: Query leaderboard_entries where user_id IN (list of accepted friend IDs from friendships table). Fix if this sub-query is broken.

4. CURRENT USER HIGHLIGHT: Find the current user's row and highlight it with a green left border (2px, #00E676). If user is not in top 100, show their rank in a pinned card at the bottom of the list.

5. REALTIME: Subscribe to `leaderboard_entries` table changes. On any change: refresh the visible list. Use Supabase stream or realtime channel.

6. PODIUM: Verify top 3 entries display correctly in the podium widget at top of screen. Fix avatar loading (use CachedNetworkImage with initial fallback).

---

GOALS SCREEN AUDIT & FIX (lib/features/goals/presentation/goals_screen.dart):

Expected behavior — verify and fix:

1. LOADING: Query `fitness_goals` where user_id = currentUser AND completed = false, ordered by ends_at ASC. Fix query if wrong.

2. PROGRESS UPDATE: When an activity session is saved, update fitness_goals.current_value for active goals:
```dart
final activeGoals = await supabase
  .from('fitness_goals')
  .select()
  .eq('user_id', userId)
  .eq('completed', false)
  .lte('starts_at', DateTime.now().toIso8601String())
  .gte('ends_at', DateTime.now().toIso8601String());

for (final goal in activeGoals) {
  double newValue = goal['current_value'];
  
  switch (goal['goal_type']) {
    case 'weekly_distance':
    case 'monthly_distance':
      newValue += session.distanceKm;
      break;
    case 'weekly_sessions':
      newValue += 1;
      break;
    case 'streak':
      // Streak is updated separately by the streak system, skip here
      break;
  }
  
  final completed = newValue >= goal['target_value'];
  
  await supabase.from('fitness_goals').update({
    'current_value': newValue,
    'completed': completed,
  }).eq('id', goal['id']);
  
  if (completed) {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'type': 'goal_completed',
      'title': 'Goal Achieved! 🎯',
      'body': 'You completed your goal!',
      'metadata': {'goal_id': goal['id']},
    });
  }
}
```

3. PROGRESS BARS: Each goal card should show a progress bar: current_value / target_value * 100%. Show percentage text. Show "X days left" or "Expired" if ends_at is past.

4. CREATE GOAL: Verify the create goal form inserts correctly into `fitness_goals` with correct starts_at (today) and ends_at (based on goal type: weekly = +7 days, monthly = +30 days).

5. COMPLETED GOALS TAB: Show goals where completed = true with a green checkmark and completed date.

6. DELETE GOAL: Add a swipe-to-delete or long-press delete on goal cards. Call `supabase.from('fitness_goals').delete().eq('id', goalId)`.

---

GLOBAL FIX — Add weight field to Settings:
In lib/features/profile/presentation/settings_screen.dart, add a "My Weight" input field:
- Number input, keyboard type: number
- Suffix: "kg"
- Saves to `profiles.weight_kg` column
- Used by calorie calculation in live activity
- Placeholder: "70 kg (used for calorie calculation)"
```

