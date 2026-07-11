import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' if (dart.library.html) 'package:turf_app/core/utils/platform_utils.dart';

class PolylineCodec {
  static String encode(List<Position> points) {
    var output = StringBuffer();
    var lastLat = 0;
    var lastLng = 0;

    for (var point in points) {
      var lat = (point.lat.toDouble() * 1e5).round();
      var lng = (point.lng.toDouble() * 1e5).round();

      var dLat = lat - lastLat;
      var dLng = lng - lastLng;

      _encodeValue(output, dLat);
      _encodeValue(output, dLng);

      lastLat = lat;
      lastLng = lng;
    }
    return output.toString();
  }

  static void _encodeValue(StringBuffer output, int value) {
    value = value < 0 ? ~(value << 1) : (value << 1);
    while (value >= 0x20) {
      output.write(String.fromCharCode((0x20 | (value & 0x1f)) + 63));
      value >>= 5;
    }
    output.write(String.fromCharCode(value + 63));
  }

  static List<Position> decode(String encoded) {
    List<Position> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      if (index >= len) {
        break;
      }
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(Position(lng / 1e5, lat / 1e5));
    }
    return points;
  }
}
