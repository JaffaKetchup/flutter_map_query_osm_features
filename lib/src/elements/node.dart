part of 'element.dart';

class Node extends OSMElement {
  final LatLng coord;

  const Node({required super.id, required this.coord, required super.tags});

  @override
  String toString() => 'Node $id @ (${coord.latitude}, ${coord.longitude})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          id == other.id &&
          coord == other.coord &&
          const DeepCollectionEquality().equals(tags, other.tags));

  @override
  int get hashCode => Object.hash(id, coord, tags);
}
