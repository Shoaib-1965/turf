# TURF — AI Agent README
> Paste this at the start of EVERY prompt to any AI agent.

---

## What is TURF?
TURF is a Pakistan-based fitness and territory capture mobile app built in Flutter. 
Users run, walk, or cycle in the real world to capture map territories, compete with friends, earn XP, 
climb leaderboards, complete challenges, and track fitness goals. Think Strava + a strategy game.


---

## Tech Stack
| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Supabase (Postgres + Auth + Realtime + Storage) |
| Maps | flutter_map + OpenStreetMap + Stadia Maps dark tiles (free, no API key) |
| GPS | geolocator package |
| State | flutter_riverpod |
| Navigation | go_router |
| Auth | Supabase Auth — Email/Password + Google OAuth (optional) |

---

## Supabase Connection
```dart
URL: https://lcrfzwxkrkiuvfhkgfju.supabase.co
AnonKey: sb_publishable_hLE459WDGvetlxZvwMhyGQ_OkwjBtGm
Package: supabase_flutter (already installed)
```

---

## Core Rules — Follow Always
- NO mock/demo data. Everything is real-time Supabase only.
- NEVER rename any table, column, or Supabase function.
- UI is #1 priority — dark-mode-first, premium athletic design.
- App weight is #2 priority — lazy load, efficient streams, minimal rebuilds.
- All Supabase calls wrapped in try/catch with friendly error messages.
- No raw error messages shown to users ever.
- Terms & Conditions: https://www.termsfeed.com/live/340e81fc-0ff8-43cf-ae39-4a335d13462a
- Must be accepted before account creation.
- Google Sign-In is optional (not forced).
- App works on Android (API 21+) and iOS (13+).

---

## UI Theme
```
Primary color:     #00E676 (electric green)
Background:        #0A0A0A
Surface:           #141414
Card:              #1C1C1E
Text primary:      #FFFFFF
Text secondary:    #8E8E93
Font body:         Inter (Google Fonts)
Font display:      Space Grotesk (Google Fonts)
```

---

## Supabase Functions (already created)
- `public.calculate_user_level(p_xp int8)` — returns user level from XP
- `public.award_xp(p_user_id uuid, p_xp int4)` — adds XP + recalculates level
- `public.update_leaderboard()` — refreshes all leaderboard entries

## Realtime Tables (already enabled)
`location_pings, territories, territory_captures, notifications, leaderboard_entries, challenge_participants, claimed_territories`

## Storage Buckets (already created)
- `avatars` — public read, authenticated write
- `activity_media` — private, user-scoped

---

## App Name & Identity
- Name: **TURF**
- Tagline: **Claim your ground.**
- Package ID: `com.turf.app`
- Google OAuth redirect: `com.turf.app://login-callback`

---

## Database Schema Reference (NEVER rename these)
```sql
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.badges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  icon_url text,
  badge_type text CHECK (badge_type = ANY (ARRAY['milestone'::text, 'challenge'::text, 'streak'::text, 'territory'::text, 'speed'::text, 'special'::text])),
  required_value double precision,
  xp_bonus integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT badges_pkey PRIMARY KEY (id)
);

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text NOT NULL UNIQUE,
  full_name text,
  avatar_url text,
  bio text,
  total_distance_km double precision DEFAULT 0,
  total_xp bigint DEFAULT 0,
  level integer DEFAULT 1,
  streak_days integer DEFAULT 0,
  last_active_date date,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  total_area_claimed_sqm double precision DEFAULT 0,
  today_area_claimed_sqm double precision DEFAULT 0,
  today_area_date date,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

CREATE TABLE public.activity_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  activity_type text CHECK (activity_type = ANY (ARRAY['run'::text, 'walk'::text, 'cycle'::text])),
  started_at timestamp with time zone,
  ended_at timestamp with time zone,
  duration_seconds integer,
  distance_km double precision,
  avg_speed_kmh double precision,
  max_speed_kmh double precision,
  calories_burned integer,
  elevation_gain_m double precision,
  route_polyline text,
  xp_earned integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT activity_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT activity_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.location_pings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid,
  user_id uuid,
  latitude double precision,
  longitude double precision,
  altitude double precision,
  speed_ms double precision,
  heading double precision,
  recorded_at timestamp with time zone DEFAULT now(),
  CONSTRAINT location_pings_pkey PRIMARY KEY (id),
  CONSTRAINT location_pings_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.activity_sessions(id),
  CONSTRAINT location_pings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.territories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text,
  center_lat double precision,
  center_lng double precision,
  radius_meters real DEFAULT 200,
  owner_id uuid,
  captured_at timestamp with time zone,
  capture_count integer DEFAULT 0,
  xp_value integer DEFAULT 50,
  territory_type text CHECK (territory_type = ANY (ARRAY['zone'::text, 'landmark'::text, 'street'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT territories_pkey PRIMARY KEY (id),
  CONSTRAINT territories_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.territory_captures (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  territory_id uuid,
  user_id uuid,
  session_id uuid,
  captured_at timestamp with time zone DEFAULT now(),
  xp_earned integer,
  CONSTRAINT territory_captures_pkey PRIMARY KEY (id),
  CONSTRAINT territory_captures_territory_id_fkey FOREIGN KEY (territory_id) REFERENCES public.territories(id),
  CONSTRAINT territory_captures_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT territory_captures_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.activity_sessions(id)
);

CREATE TABLE public.friendships (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  requester_id uuid,
  addressee_id uuid,
  status text CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'blocked'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT friendships_pkey PRIMARY KEY (id),
  CONSTRAINT friendships_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.profiles(id),
  CONSTRAINT friendships_addressee_id_fkey FOREIGN KEY (addressee_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.challenges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_by uuid,
  title text NOT NULL,
  description text,
  challenge_type text CHECK (challenge_type = ANY (ARRAY['distance'::text, 'territory'::text, 'streak'::text, 'speed'::text, 'elevation'::text])),
  target_value double precision,
  activity_type text CHECK (activity_type = ANY (ARRAY['run'::text, 'walk'::text, 'cycle'::text, 'any'::text])),
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  is_public boolean DEFAULT true,
  xp_reward integer DEFAULT 100,
  badge_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT challenges_pkey PRIMARY KEY (id),
  CONSTRAINT challenges_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id),
  CONSTRAINT challenges_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badges(id)
);

CREATE TABLE public.challenge_participants (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  challenge_id uuid,
  user_id uuid,
  joined_at timestamp with time zone DEFAULT now(),
  current_value double precision DEFAULT 0,
  completed boolean DEFAULT false,
  completed_at timestamp with time zone,
  CONSTRAINT challenge_participants_pkey PRIMARY KEY (id),
  CONSTRAINT challenge_participants_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.challenges(id),
  CONSTRAINT challenge_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.leaderboard_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  leaderboard_type text CHECK (leaderboard_type = ANY (ARRAY['weekly_distance'::text, 'monthly_distance'::text, 'territory_count'::text, 'total_xp'::text, 'streak'::text])),
  value double precision,
  rank integer,
  period_start date,
  period_end date,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT leaderboard_entries_pkey PRIMARY KEY (id),
  CONSTRAINT leaderboard_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.user_badges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  badge_id uuid,
  earned_at timestamp with time zone DEFAULT now(),
  session_id uuid,
  CONSTRAINT user_badges_pkey PRIMARY KEY (id),
  CONSTRAINT user_badges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_badges_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badges(id),
  CONSTRAINT user_badges_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.activity_sessions(id)
);

CREATE TABLE public.fitness_goals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  goal_type text CHECK (goal_type = ANY (ARRAY['weekly_distance'::text, 'monthly_distance'::text, 'weekly_sessions'::text, 'weight_loss'::text, 'streak'::text])),
  target_value double precision,
  current_value double precision DEFAULT 0,
  unit text,
  starts_at date,
  ends_at date,
  completed boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fitness_goals_pkey PRIMARY KEY (id),
  CONSTRAINT fitness_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  type text CHECK (type = ANY (ARRAY['friend_request'::text, 'territory_stolen'::text, 'challenge_invite'::text, 'badge_earned'::text, 'goal_completed'::text, 'leaderboard_rank'::text, 'club_request'::text, 'club_joined'::text, 'friend_accepted'::text])),
  title text,
  body text,
  is_read boolean DEFAULT false,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.clubs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  avatar_url text,
  cover_url text,
  created_by uuid,
  is_public boolean DEFAULT true,
  invite_code text DEFAULT "substring"((gen_random_uuid())::text, 1, 8) UNIQUE,
  member_count integer DEFAULT 1,
  total_distance_km double precision DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT clubs_pkey PRIMARY KEY (id),
  CONSTRAINT clubs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);

CREATE TABLE public.club_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  club_id uuid,
  user_id uuid,
  role text DEFAULT 'member'::text CHECK (role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text])),
  weekly_distance_km double precision DEFAULT 0,
  total_distance_km double precision DEFAULT 0,
  joined_at timestamp with time zone DEFAULT now(),
  CONSTRAINT club_members_pkey PRIMARY KEY (id),
  CONSTRAINT club_members_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id),
  CONSTRAINT club_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.club_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  club_id uuid,
  user_id uuid,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT club_requests_pkey PRIMARY KEY (id),
  CONSTRAINT club_requests_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id),
  CONSTRAINT club_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.club_activities (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  club_id uuid,
  session_id uuid,
  user_id uuid,
  posted_at timestamp with time zone DEFAULT now(),
  CONSTRAINT club_activities_pkey PRIMARY KEY (id),
  CONSTRAINT club_activities_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id),
  CONSTRAINT club_activities_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.activity_sessions(id),
  CONSTRAINT club_activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

CREATE TABLE public.spatial_ref_sys (
  srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
  auth_name character varying,
  auth_srid integer,
  srtext character varying,
  proj4text character varying,
  CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);

CREATE TABLE public.claimed_territories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid,
  session_id uuid,
  geom USER-DEFINED NOT NULL,
  area_sqm double precision NOT NULL DEFAULT 0,
  perimeter_m double precision NOT NULL DEFAULT 0,
  color_hex text DEFAULT '#00E676'::text,
  claimed_at timestamp with time zone DEFAULT now(),
  is_active boolean DEFAULT true,
  CONSTRAINT claimed_territories_pkey PRIMARY KEY (id),
  CONSTRAINT claimed_territories_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id),
  CONSTRAINT claimed_territories_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.activity_sessions(id)
);
```
