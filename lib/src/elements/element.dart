import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../query/query_features.dart';

part 'node.dart';
part 'relation.dart';
part 'way.dart';

sealed class OSMElement {
  final int id;
  final Map<String, String>? tags;

  const OSMElement({required this.id, this.tags});

  @override
  String toString();
  @override
  bool operator ==(Object other);
  @override
  int get hashCode;
}

typedef LatLngBounds = (LatLng min, LatLng max);
