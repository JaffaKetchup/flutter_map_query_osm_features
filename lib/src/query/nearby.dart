part of 'query_features.dart';

Future<Iterable<OSMElement>> _nearby({
  required Uri endpoint,
  required int radius,
  required LatLng point,
}) async {
  final Map<String, dynamic> response = json.decode(
    const Utf8Decoder().convert(
      (await http.post(
        endpoint,
        body:
            '[timeout:60][out:json];node(around:$radius,${point.latitude},${point.longitude});out;way(around:$radius,${point.latitude},${point.longitude});out geom;relation(around:$radius,${point.latitude},${point.longitude});out tags bb;',
      ))
          .body
          .codeUnits,
    ),
  );

  final List<Map<String, dynamic>> elementsRaw =
      (response['elements']! as List).cast();

  return () sync* {
    for (final element in elementsRaw) {
      final int id = element['id'];
      final Map<String, String>? tags = (element['tags'] as Map?)?.cast();

      switch (element['type']!) {
        case 'node':
          yield Node(
            id: id,
            coord: LatLng(element['lat'], element['lon']),
            tags: tags,
          );
          break;
        case 'way':
          final Map<String, dynamic> bounds = element['bounds'];
          yield Way.full(
            id: id,
            bounds: (
              LatLng(bounds['minlat'], bounds['minlon']),
              LatLng(bounds['maxlat'], bounds['maxlon']),
            ),
            nodes: (element['nodes'] as List).cast(),
            coords: (element['geometry'] as List)
                .cast<Map<String, dynamic>>()
                .map((g) => LatLng(g['lat']!, g['lon']!))
                .toList(),
            tags: tags,
          );
          break;
        case 'relation':
          final Map<String, dynamic> bounds = element['bounds'];
          yield Relation(
            id: id,
            bounds: (
              LatLng(bounds['minlat'], bounds['minlon']),
              LatLng(bounds['maxlat'], bounds['maxlon']),
            ),
            tags: tags,
          );
          break;
      }
    }
  }();
}
