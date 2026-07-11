import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/theme/theme_provider.dart';
import 'package:turf_app/core/router/app_router.dart';
import 'package:turf_app/core/services/background_tracking_service.dart' as turf_bg;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' if (dart.library.html) 'package:turf_app/core/utils/platform_utils.dart';
import 'package:turf_app/core/constants/map_constants.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:turf_app/features/profile/presentation/providers/profile_provider.dart';
//ok
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://lcrfzwxkrkiuvfhkgfju.supabase.co',
    anonKey: 'sb_publishable_hLE459WDGvetlxZvwMhyGQ_OkwjBtGm',
  );

  if (!kIsWeb) {
    // Load environment variables for AI Coach (Fireworks API)
    await dotenv.load(fileName: '.env').catchError((_) {
      // .env file may not exist yet — AI Coach will run in stub mode
    });
    
    MapboxOptions.setAccessToken(MapConstants.mapboxAccessToken);
    await turf_bg.BackgroundTrackingService.initialize();
  }
  
  runApp(
    const ProviderScope(
      child: TurfApp(),
    ),
  );
}

class TurfApp extends ConsumerStatefulWidget {
  const TurfApp({super.key});

  @override
  ConsumerState<TurfApp> createState() => _TurfAppState();
}

class _TurfAppState extends ConsumerState<TurfApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.userDeleted) {
        ref.invalidate(profileProvider);
        // invalidate other user-specific providers here if added later
      }
      if (event == AuthChangeEvent.signedIn) {
        ref.refresh(profileProvider);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'TURF',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}