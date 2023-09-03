part of 'element.dart';

sealed class Way extends OSMElement {
  final LatLngBounds bounds;

  const Way({
    required super.id,
    required this.bounds,
    required super.tags,
  });

  const factory Way.full({
    required int id,
    required LatLngBounds bounds,
    required List<int> nodes,
    required List<LatLng> coords,
    required Map<String, String>? tags,
  }) = FullWay._;

  const factory Way.partial({
    required int id,
    required LatLngBounds bounds,
    required Map<String, String>? tags,
  }) = PartialWay._;

  bool get isPartial => this is PartialWay;

  Future<FullWay> getFullData();
}

class FullWay extends Way {
  final List<int> nodes;
  final List<LatLng> coords;

  const FullWay._({
    required super.id,
    required super.bounds,
    required this.nodes,
    required this.coords,
    required super.tags,
  });

  @override
  Future<FullWay> getFullData() async => this;

  @override
  String toString() => '(Full)Way $id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FullWay &&
          id == other.id &&
          bounds == other.bounds &&
          nodes == other.nodes &&
          coords == other.coords &&
          const DeepCollectionEquality().equals(tags, other.tags));

  @override
  int get hashCode => Object.hash(id, bounds, nodes, coords, tags);
}

class PartialWay extends Way {
  const PartialWay._({
    required super.id,
    required super.bounds,
    required super.tags,
  });

  @override
  Future<FullWay> getFullData() async {
    final Map<String, dynamic> response = json.decode(
      const Utf8Decoder(allowMalformed: true).convert(
        (await http.get(
          Uri.parse('${QueryFeatures().osmApiEndpoint}way/$id/full.json'),
        ))
            .body
            .codeUnits,
      ),
    );

    final List<Map<String, dynamic>> elementsRaw =
        (response['elements']! as List).cast();

    final nodeIds = <int>[];
    final nodeCoords = <LatLng>[];

    for (final element in elementsRaw) {
      if (element['type'] != 'node') continue;
      nodeIds.add(element['id']);
      nodeCoords.add(LatLng(element['lat'], element['lon']));
    }

    return FullWay._(
      id: id,
      bounds: bounds,
      nodes: nodeIds,
      coords: nodeCoords,
      tags: tags,
    );
  }

  @override
  String toString() => '(Partial)Way $id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FullWay &&
          id == other.id &&
          bounds == other.bounds &&
          const DeepCollectionEquality().equals(tags, other.tags));

  @override
  int get hashCode => Object.hash(id, bounds, tags);
}
