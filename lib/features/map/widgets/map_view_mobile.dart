import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:turf_app/core/constants/map_constants.dart';

class TurfMapView extends StatelessWidget {
  final void Function(MapboxMap)? onMapCreated;
  final CameraOptions? cameraOptions;
  
  const TurfMapView({super.key, this.onMapCreated, this.cameraOptions});
  
  @override
  Widget build(BuildContext context) {
    return MapWidget(
      styleUri: MapConstants.mapboxStyleUri,
      cameraOptions: cameraOptions,
      onMapCreated: onMapCreated,
    );
  }
}
