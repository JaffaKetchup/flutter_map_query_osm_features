import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../elements/element.dart';

part 'nearby.dart';
part 'enclosing.dart';

typedef OSMElementsAroundPoint = ({
  Iterable<OSMElement> nearby,
  Iterable<OSMElement> enclosing,
});

final class QueryFeatures {
  factory QueryFeatures({
    String overpassEndpoint = 'https://overpass-api.de/api/interpreter',
    String osmApiEndpoint = 'https://api.openstreetmap.org/api/0.6/',
    bool forceInitialiseNew = false,
  }) {
    if (forceInitialiseNew) _instance = null;

    if (_instance == null) {
      assert(
        osmApiEndpoint.substring(osmApiEndpoint.length - 1) == '/',
        "`osmApiEndpoint` must end in '/'",
      );
    }

    return _instance ??= QueryFeatures._(
      overpassEndpoint: Uri.parse(overpassEndpoint),
      osmApiEndpoint: Uri.parse(osmApiEndpoint),
    );
  }

  const QueryFeatures._({
    required this.overpassEndpoint,
    required this.osmApiEndpoint,
  });

  static QueryFeatures? _instance;
  static bool get isInitialized => _instance != null;

  final Uri overpassEndpoint;
  final Uri osmApiEndpoint;

  Future<OSMElementsAroundPoint> getElements({
    required int radius,
    required LatLng point,
  }) async =>
      (
        nearby: await _nearby(
          endpoint: overpassEndpoint,
          radius: radius,
          point: point,
        ),
        enclosing: await _point(
          endpoint: overpassEndpoint,
          point: point,
        ),
      );

  void format(OSMElementsAroundPoint elements) {}
}
