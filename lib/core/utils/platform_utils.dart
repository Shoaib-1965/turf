import 'package:flutter/foundation.dart' show kIsWeb;

bool get isMobile => !kIsWeb;
bool get isWeb => kIsWeb;

// Stubs for web compilation
class MapboxOptions {
  static void setAccessToken(String token) {}
}

class MapAnimationOptions {
  MapAnimationOptions({dynamic duration, dynamic startDelay, dynamic bearing, dynamic pitch});
}

class CircleAnnotationOptions {
  CircleAnnotationOptions({dynamic geometry, dynamic circleColor, dynamic circleRadius, dynamic circleStrokeWidth, dynamic circleStrokeColor, dynamic circleOpacity, dynamic circleStrokeOpacity});
}

class MbxImage {
  MbxImage({dynamic width, dynamic height, dynamic data});
}

class PolylineAnnotationManager {
  Future<PolylineAnnotation> create(PolylineAnnotationOptions options) async => PolylineAnnotation();
  Future<void> update(PolylineAnnotation annotation) async {}
}

class CircleAnnotationManager {
  Future<void> deleteAll() async {}
  Future<void> delete(CircleAnnotation annotation) async {}
  Future<CircleAnnotation> create(CircleAnnotationOptions options) async => CircleAnnotation();
  Future<List<CircleAnnotation>> createMulti(List<CircleAnnotationOptions> options) async => [];
  Future<void> update(CircleAnnotation annotation) async {}
}

class PolylineAnnotation {
  dynamic geometry;
}

class CircleAnnotation {
  dynamic circleRadius;
  dynamic circleOpacity;
  dynamic circleStrokeOpacity;
}

class GeoJsonSource {
  GeoJsonSource({dynamic id, dynamic data});
}

class FillLayer {
  FillLayer({dynamic id, dynamic sourceId, dynamic fillColor, dynamic fillOpacity, dynamic fillPattern});
}

class LineLayer {
  LineLayer({dynamic id, dynamic sourceId, dynamic lineColor, dynamic lineWidth});
}

class PointAnnotationOptions {
  PointAnnotationOptions({dynamic geometry, dynamic image, dynamic iconSize});
}

class Position {
  final num lng;
  final num lat;
  Position(this.lng, this.lat);
}

class CameraOptions {
  final dynamic center;
  final double? zoom;
  final double? pitch;
  final double? bearing;
  CameraOptions({this.center, this.zoom, this.pitch, this.bearing});
}

class MapboxMap {
  final dynamic annotations = _AnnotationsStub();
  final dynamic gestures = _GesturesStub();
  final dynamic style = _StyleStub();
  Future<void> setCamera(CameraOptions cameraOptions) async {}
  Future<void> flyTo(CameraOptions cameraOptions, dynamic animationOptions) async {}
  Future<dynamic> getStyle() async => null;
  Future<void> loadStyleURI(String styleUri) async {}
  Future<CameraOptions> cameraForCoordinates(List<Point> coordinates, MbxEdgeInsets padding, dynamic bearing, dynamic pitch) async => CameraOptions();
}

class _StyleStub {
  Future<void> addStyleImage(String imageId, dynamic scale, MbxImage image, bool sdf, List<dynamic> stretchX, List<dynamic> stretchY, dynamic content) async {}
  Future<void> addSource(dynamic source) async {}
  Future<void> addLayer(dynamic layer, {dynamic layerPosition}) async {}
}

class _GesturesStub {
  void updateSettings(GesturesSettings settings) {}
}

class GesturesSettings {
  GesturesSettings({
    dynamic scrollEnabled,
    dynamic pinchToZoomEnabled,
    dynamic doubleTapToZoomInEnabled,
    dynamic doubleTouchToZoomOutEnabled,
    dynamic quickZoomEnabled,
    dynamic pitchEnabled,
    dynamic rotateEnabled,
  });
}

class _AnnotationsStub {
  Future<PolylineAnnotationManager> createPolylineAnnotationManager() async => PolylineAnnotationManager();
  Future<CircleAnnotationManager> createCircleAnnotationManager() async => CircleAnnotationManager();
  Future<PointAnnotationManager> createPointAnnotationManager() async => PointAnnotationManager();
}

class PointAnnotationManager {
  Future<PointAnnotation> create(PointAnnotationOptions options) async => PointAnnotation();
  Future<void> update(PointAnnotation annotation) async {}
  Future<void> delete(PointAnnotation annotation) async {}
  Future<void> deleteAll() async {}
}

class PointAnnotation {
  dynamic geometry;
}

class PolylineAnnotationOptions {
  PolylineAnnotationOptions({dynamic geometry, dynamic lineColor, dynamic lineWidth});
}

class LineString {
  LineString({dynamic coordinates});
}

class Point {
  Point({dynamic coordinates});
}

class MbxEdgeInsets {
  MbxEdgeInsets({dynamic top, dynamic left, dynamic bottom, dynamic right});
}
