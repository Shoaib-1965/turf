import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:confetti/confetti.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turf_app/core/services/geocoding_service.dart';
import 'package:turf_app/features/map/domain/models/territory.dart';
import 'package:turf_app/features/map/domain/models/claimed_territory.dart';
import 'package:turf_app/features/map/data/territory_claim_repository.dart';
import 'package:turf_app/features/map/utils/style_image_cache.dart';
import 'package:turf_app/features/map/presentation/providers/location_provider.dart';
import 'package:turf_app/features/map/presentation/providers/territories_provider.dart';
import 'package:turf_app/features/map/presentation/widgets/floating_bottom_stats.dart';
import 'package:turf_app/features/map/presentation/widgets/floating_top_bar.dart';
import 'package:turf_app/features/map/presentation/widgets/territory_info_sheet.dart';
import 'package:turf_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:turf_app/features/ai_coach/presentation/widgets/coach_fab.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _userMarkerManager;
  PointAnnotation? _userMarker;
  CircleAnnotationManager? _territoryManager;
  PointAnnotationManager? _searchMarkerManager;
  PointAnnotation? _searchMarker;

  late ConfettiController _confettiController;
  bool _hasInitialFlown = false;

  Timer? _searchMarkerTimer;
  String? _avatarUrl;
  String? _username;
  bool _showPermissionBanner = false;

  // Claimed territories
  StyleImageCache? _styleImageCache;
  List<ClaimedTerritory> _claimedTerritories = [];
  int _claimedLayerCounter = 0;
  final Set<String> _renderedClaimIds = {};
  RealtimeChannel? _claimedRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermissionFlow();
    });
  }

  Future<void> _checkLocationPermissionFlow() async {
    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.whileInUse || 
        permission == geo.LocationPermission.always) {
      if (mounted) setState(() => _showPermissionBanner = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool permanentlyDenied = prefs.getBool('location_permission_denied_permanently') ?? false;
    final int askCount = prefs.getInt('location_permission_ask_count') ?? 0;

    if (permission == geo.LocationPermission.deniedForever) {
      await prefs.setBool('location_permission_denied_permanently', true);
      if (mounted) setState(() => _showPermissionBanner = true);
      return;
    }

    if (permanentlyDenied || askCount >= 3) {
      if (mounted) setState(() => _showPermissionBanner = true);
      return;
    }

    if (mounted) {
      _showCustomPermissionDialog(prefs, askCount);
    }
  }

  void _showCustomPermissionDialog(SharedPreferences prefs, int askCount) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 64,
                    width: 64,
                    child: Lottie.asset(
                      'assets/lottie/location.json',
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.location_on, color: Color(0xFF00E676), size: 64),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "TURF Needs Your Location",
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "To track your runs, capture territories, and show you on the map, TURF needs access to your location while you're using the app.",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final status = await geo.Geolocator.requestPermission();
                        if (status == geo.LocationPermission.whileInUse || status == geo.LocationPermission.always) {
                          ref.invalidate(locationProvider);
                          _checkLocationPermissionFlow();
                        } else {
                          await prefs.setInt('location_permission_ask_count', askCount + 1);
                          if (status == geo.LocationPermission.deniedForever) {
                            await prefs.setBool('location_permission_denied_permanently', true);
                          }
                          _checkLocationPermissionFlow();
                        }
                      },
                      child: const Text("Allow Location", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await prefs.setInt('location_permission_ask_count', askCount + 1);
                      _checkLocationPermissionFlow();
                    },
                    child: const Text(
                      "Not Now",
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchProfileData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url, username')
          .eq('id', userId)
          .maybeSingle();
          
      if (data != null && mounted) {
        setState(() {
          _avatarUrl = data['avatar_url'];
          _username = data['username'];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _searchMarkerTimer?.cancel();
    _claimedRealtimeChannel?.unsubscribe();
    _styleImageCache?.clear();
    super.dispose();
  }

  Future<Uint8List> _createMarkerImage() async {
    final size = const ui.Size(132, 156);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final paint = Paint()..color = const Color(0xFF00E676);
    
    final path = Path()
      ..moveTo(size.width / 2 - 18, size.height - 30)
      ..lineTo(size.width / 2 + 18, size.height - 30)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final circleCenter = Offset(size.width / 2, size.width / 2);
    final circleRadius = size.width / 2;
    canvas.drawCircle(circleCenter, circleRadius, paint);

    final innerRadius = circleRadius - 6;
    final innerPaint = Paint()..color = const Color(0xFF1C1C1E);
    canvas.drawCircle(circleCenter, innerRadius, innerPaint);
    
    bool imageDrawn = false;
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      try {
        final Completer<ImageInfo> completer = Completer();
        final imgProvider = CachedNetworkImageProvider(_avatarUrl!);
        final stream = imgProvider.resolve(const ImageConfiguration());
        
        late ImageStreamListener listener;
        listener = ImageStreamListener((info, _) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete(info);
        }, onError: (exception, stackTrace) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.completeError(exception);
        });
        
        stream.addListener(listener);
        final imageInfo = await completer.future;
        
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: circleCenter, radius: innerRadius)));
        
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: circleCenter, radius: innerRadius),
          image: imageInfo.image,
          fit: BoxFit.cover,
        );
        
        canvas.restore();
        imageDrawn = true;
      } catch (e) {
        // Fallback to initial
      }
    }
    
    if (!imageDrawn) {
      final initial = (_username != null && _username!.isNotEmpty) ? _username![0].toUpperCase() : '?';
      final textPainter = TextPainter(
        text: TextSpan(
          text: initial,
          style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(circleCenter.dx - textPainter.width / 2, circleCenter.dy - textPainter.height / 2));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createSearchMarkerImage() async {
    final size = const ui.Size(120, 120);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(const Offset(60, 60), 60, paint);
    
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(60, 60), 20, innerPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _styleImageCache = StyleImageCache(mapboxMap);
    
    // Set map style
    await mapboxMap.loadStyleURI('mapbox://styles/shoaib1965/cmqm2b0qd009m01s1h9773jnl');
    
    // Set night light preset for dark mode
    await mapboxMap.style.setStyleImportConfigProperty('basemap', 'lightPreset', 'night');

    // Create annotation managers
    _userMarkerManager = await mapboxMap.annotations.createPointAnnotationManager();
    _territoryManager = await mapboxMap.annotations.createCircleAnnotationManager();
    _searchMarkerManager = await mapboxMap.annotations.createPointAnnotationManager();

    // Load claimed territories
    _loadClaimedTerritories();
    _subscribeToClaimedTerritories();
  }

  // ─── Claimed Territories ─────────────────────────────────────

  Future<void> _loadClaimedTerritories() async {
    try {
      final repo = ref.read(territoryClaimRepositoryProvider);
      _claimedTerritories = await repo.fetchClaimedTerritories();
      for (final ct in _claimedTerritories) {
        await _renderClaimedTerritory(ct);
      }
    } catch (_) {}
  }

  void _subscribeToClaimedTerritories() {
    final repo = ref.read(territoryClaimRepositoryProvider);
    _claimedRealtimeChannel = repo.subscribeToClaimedTerritories(
      onInsert: (ct) {
        if (mounted && !_renderedClaimIds.contains(ct.id)) {
          setState(() {
            _claimedTerritories.add(ct);
          });
          _renderClaimedTerritory(ct);
        }
      },
    );
  }

  Future<void> _renderClaimedTerritory(ClaimedTerritory ct) async {
    if (_mapboxMap == null || ct.polygon.isEmpty || _renderedClaimIds.contains(ct.id)) return;
    _renderedClaimIds.add(ct.id);

    _claimedLayerCounter++;
    final sourceId = 'claimed_src_${ct.id}';
    final fillLayerId = 'claimed_fill_$_claimedLayerCounter';
    final lineLayerId = 'claimed_line_$_claimedLayerCounter';

    // Build GeoJSON
    final ring = ct.polygon.map((p) => [p.lng.toDouble(), p.lat.toDouble()]).toList();
    if (ring.isNotEmpty && (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add(List<double>.from(ring.first));
    }

    final geoJson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [ring],
          },
          'properties': {
            'owner_id': ct.ownerId,
            'territory_id': ct.id,
          },
        }
      ],
    });

    try {
      await _mapboxMap!.style.addSource(GeoJsonSource(id: sourceId, data: geoJson));

      // Try to register owner avatar as fill pattern
      String? patternId;
      if (_styleImageCache != null) {
        try {
          patternId = await _styleImageCache!.registerAvatar(
            userId: ct.ownerId,
            avatarUrl: ct.ownerAvatarUrl,
            displayName: ct.ownerName,
            colorHex: ct.ownerTerraColor,
          );
        } catch (_) {}
      }

      final color = _parseColor(ct.ownerTerraColor);

      if (patternId != null && _styleImageCache!.hasImage(ct.ownerId)) {
        // Avatar-pattern fill
        await _mapboxMap!.style.addLayer(FillLayer(
          id: fillLayerId,
          sourceId: sourceId,
          fillPattern: patternId,
          fillOpacity: 0.45,
        ));
      } else {
        // Flat color fallback
        await _mapboxMap!.style.addLayer(FillLayer(
          id: fillLayerId,
          sourceId: sourceId,
          fillColor: color.value,
          fillOpacity: 0.35,
        ));
      }

      // Border line
      await _mapboxMap!.style.addLayer(LineLayer(
        id: lineLayerId,
        sourceId: sourceId,
        lineColor: color.value,
        lineWidth: 2.0,
      ));
    } catch (_) {
      // Graceful fallback
    }
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _showClaimedTerritoryInfo(ClaimedTerritory ct) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF00E676),
                  child: ct.ownerAvatarUrl != null
                      ? ClipOval(child: Image.network(ct.ownerAvatarUrl!, fit: BoxFit.cover, width: 56, height: 56))
                      : Text(
                          (ct.ownerName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ct.ownerName ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LVL ${ct.ownerLevel}', 
                              style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${ct.ownerXp} XP',
                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Claimed ${_timeAgo(ct.claimedAt)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoStat(label: 'Area', value: ct.formattedArea),
                _InfoStat(label: 'Perimeter', value: '${ct.perimeterM.round()} m'),
                _InfoStat(label: 'Size', value: _funSizeComparison(ct.areaSqm)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _funSizeComparison(double sqm) {
    // Football pitch is ~7,140 sqm
    final pitches = sqm / 7140.0;
    if (pitches >= 1.0) return '${pitches.toStringAsFixed(1)}x ⚽';
    return '${(pitches * 100).round()}% ⚽';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  // ─── Existing map features ───────────────────────────────────

  void _onSearchLocationSelected(Position coordinates, String label) async {
    if (_mapboxMap == null || _searchMarkerManager == null) return;
    
    _mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: coordinates), zoom: 16.0),
      MapAnimationOptions(duration: 2000),
    );

    final image = await _createSearchMarkerImage();
    if (_searchMarker != null) {
      _searchMarkerManager!.delete(_searchMarker!);
    }
    
    _searchMarker = await _searchMarkerManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: coordinates),
        image: image,
        iconSize: 0.5,
      ),
    );

    _searchMarkerTimer?.cancel();
    _searchMarkerTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _searchMarker != null) {
        _searchMarkerManager?.delete(_searchMarker!);
        _searchMarker = null;
      }
    });
  }

  void _showTerritoryInfo(Territory territory, Position? userPos) {
    bool canCapture = false;
    
    if (userPos != null) {
      final distance = geo.Geolocator.distanceBetween(
        userPos.lat.toDouble(), userPos.lng.toDouble(),
        territory.center.lat.toDouble(), territory.center.lng.toDouble(),
      );
      canCapture = distance <= territory.radiusMeters;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnedByMe = territory.ownerId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TerritoryInfoSheet(
        territory: territory,
        canCapture: canCapture,
        isOwnedByMe: isOwnedByMe,
        onCapture: () async {
          Navigator.pop(context);
          try {
            await ref.read(territoryRepositoryProvider).captureTerritory(
                  territory.id,
                  territory.xpValue,
                );
            _confettiController.play();

            _autoNameTerritory(territory);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Captured! +${territory.xpValue} XP'),
                  backgroundColor: const Color(0xFF00E676),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to capture territory.'),
                  backgroundColor: Color(0xFFFF453A),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _autoNameTerritory(Territory territory) async {
    final name = territory.name.toLowerCase();
    if (name.startsWith('territory') || name.isEmpty || name.startsWith('unnamed')) {
      try {
        final geocodingService = GeocodingService();
        final result = await geocodingService.reverseGeocode(
          lat: territory.center.lat.toDouble(),
          lng: territory.center.lng.toDouble(),
        );
        if (result != null) {
          final newName = result.territoryName;
          await Supabase.instance.client
              .from('territories')
              .update({'name': newName})
              .eq('id', territory.id);
        }
      } catch (_) {}
    }
  }

  final Map<String, String> _userTerraColorsCache = {};

  Color _getTerritoryColor(Territory territory, String currentUserColor) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (territory.ownerId == null) return Colors.white;
    if (territory.ownerId == currentUserId) return _parseColor(currentUserColor);
    
    final ownerColor = _userTerraColorsCache[territory.ownerId!];
    if (ownerColor != null) {
      return _parseColor(ownerColor);
    } else {
      // Async fetch the color and cache it, then rebuild
      _fetchUserTerraColor(territory.ownerId!);
      return const Color(0xFFFF453A); // Default fallback while loading
    }
  }

  Future<void> _fetchUserTerraColor(String userId) async {
    if (_userTerraColorsCache.containsKey(userId)) return;
    _userTerraColorsCache[userId] = '#FF453A'; // Prevent multiple requests
    try {
      final res = await Supabase.instance.client.from('profiles').select('terra_color').eq('id', userId).single();
      if (mounted) {
        setState(() {
          _userTerraColorsCache[userId] = res['terra_color'] as String? ?? '#00E676';
        });
      }
    } catch (_) {}
  }

  void _updateTerritories(List<Territory> territories, Position? currentPos, String currentUserColor) async {
    if (_territoryManager == null) return;
    
    await _territoryManager!.deleteAll();
    
    final List<CircleAnnotationOptions> circles = [];
    for (var t in territories) {
      final color = _getTerritoryColor(t, currentUserColor);
      circles.add(CircleAnnotationOptions(
        geometry: Point(coordinates: t.center),
        circleRadius: t.radiusMeters,
        circleColor: color.value,
        circleOpacity: t.ownerId == null ? 0.2 : 0.4,
        circleStrokeColor: color.value,
        circleStrokeWidth: t.ownerId == null ? 2.0 : 0.0,
      ));
    }
    
    if (circles.isNotEmpty) {
      await _territoryManager!.createMulti(circles);
    }
  }

  void _updateUserLocation(Position pos) async {
    if (_mapboxMap == null || _userMarkerManager == null) return;
    
    if (!_hasInitialFlown) {
      _hasInitialFlown = true;
      _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: pos),
          zoom: 16.0,
          pitch: 45.0,
          bearing: 0.0,
        ),
        MapAnimationOptions(duration: 3500),
      );
    }

    final image = await _createMarkerImage();
    
    if (_userMarker != null) {
      _userMarkerManager!.delete(_userMarker!);
    }
    
    _userMarker = await _userMarkerManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: pos),
        image: image,
        iconSize: 0.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);
    final territoriesAsync = ref.watch(territoriesProvider);
    final profileAsync = ref.watch(profileProvider);
    
    final currentUserColor = profileAsync.value?.terraColor ?? '#00E676';

    Position? currentPos;
    locationAsync.whenData((pos) {
      currentPos = Position(pos.longitude, pos.latitude);
      _updateUserLocation(currentPos!);
    });

    List<Territory> territories = territoriesAsync.value ?? [];
    if (_territoryManager != null) {
      _updateTerritories(territories, currentPos, currentUserColor);
    }

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mainMap'),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(2.3522, 48.8566)), // Paris Default
              zoom: 1.5, // Globe projection initially
              pitch: 0.0,
            ),
            onMapCreated: _onMapCreated,
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFF00E676), Colors.white, Colors.yellow],
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(
              onLocationSelected: _onSearchLocationSelected,
            ),
          ),
          if (_showPermissionBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ph.openAppSettings();
                          },
                          child: const Text(
                            "Location off — tap to enable in Settings",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _showPermissionBanner = false);
                        },
                        child: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _MyLocationFab(
                    isLocating: !locationAsync.hasValue,
                    onTap: () {
                      if (locationAsync.hasValue) {
                        final pos = locationAsync.value!;
                        final geoPos = Position(pos.longitude, pos.latitude);
                        _mapboxMap?.flyTo(
                          CameraOptions(
                            center: Point(coordinates: geoPos),
                            zoom: 16.0,
                            pitch: 45.0,
                            bearing: 0.0,
                          ),
                          MapAnimationOptions(duration: 800),
                        );
                      }
                    },
                  ),
                ),
                const FloatingBottomStats(),
              ],
            ),
          ),

          // --- AI COACH FAB ---
          Positioned(
            bottom: 240,
            right: 16,
            child: CoachFab(
              onTap: () => context.push('/ai-coach'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _MyLocationFab extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLocating;

  const _MyLocationFab({required this.onTap, this.isLocating = false});

  @override
  State<_MyLocationFab> createState() => _MyLocationFabState();
}

class _MyLocationFabState extends State<_MyLocationFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    if (widget.isLocating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MyLocationFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLocating && !oldWidget.isLocating) {
      _controller.repeat();
    } else if (!widget.isLocating && oldWidget.isLocating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: RotationTransition(
            turns: _controller,
            child: const Icon(
              Icons.my_location,
              size: 20,
              color: Color(0xFF00E676),
            ),
          ),
        ),
      ),
    );
  }
}
