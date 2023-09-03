part of 'query_features.dart';

Future<Iterable<OSMElement>> _point({
  required Uri endpoint,
  required LatLng point,
}) async {
  final Map<String, dynamic> response = json.decode(
    const Utf8Decoder().convert(
      (await http.post(
        endpoint,
        body:
            '[timeout:60][out:json];is_in(${point.latitude},${point.longitude})->.a;(way(pivot.a);relation(pivot.a););out tags bb;',
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
      final Map<String, dynamic> boundsRaw = element['bounds'];
      final LatLngBounds bounds = (
        LatLng(boundsRaw['minlat'], boundsRaw['minlon']),
        LatLng(boundsRaw['maxlat'], boundsRaw['maxlon']),
      );
      final Map<String, String>? tags = (element['tags'] as Map?)?.cast();

      switch (element['type']!) {
        case 'way':
          yield Way.partial(id: id, bounds: bounds, tags: tags);
          break;
        case 'relation':
          yield Relation(id: id, bounds: bounds, tags: tags);
          break;
      }
    }
  }();
}
