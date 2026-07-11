import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:turf_app/core/constants/map_constants.dart';
import 'package:turf_app/core/utils/platform_utils.dart'; // For MapboxMap stub

class TurfMapView extends StatefulWidget {
  final void Function(MapboxMap)? onMapCreated;
  final dynamic cameraOptions;
  
  const TurfMapView({super.key, this.onMapCreated, this.cameraOptions});
  
  @override
  State<TurfMapView> createState() => _TurfMapViewWebState();
}

class _TurfMapViewWebState extends State<TurfMapView> {
  final String _viewId = 'mapbox-map-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final mapDiv = html.DivElement()
        ..id = 'map-$_viewId'
        ..style.width = '100%'
        ..style.height = '100%';
      
      // Inject Mapbox GL JS initialization script
      final script = html.ScriptElement()
        ..text = '''
          (function() {
            function initMap() {
              if (typeof mapboxgl === 'undefined') {
                setTimeout(initMap, 100);
                return;
              }
              mapboxgl.accessToken = '${MapConstants.mapboxAccessToken}';
              var map = new mapboxgl.Map({
                container: 'map-$_viewId',
                style: '${MapConstants.mapboxStyleUri}',
                center: [72.9784, 31.7197],
                zoom: 12,
                pitch: 45,
              });
              map.addControl(new mapboxgl.NavigationControl());
              map.addControl(new mapboxgl.GeolocateControl({
                positionOptions: { enableHighAccuracy: true },
                trackUserLocation: true,
              }));
            }
            initMap();
          })();
        ''';
      
      mapDiv.append(script);
      return mapDiv;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
