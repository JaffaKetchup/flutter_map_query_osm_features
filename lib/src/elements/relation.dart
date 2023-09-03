part of 'element.dart';

class Relation extends OSMElement {
  final LatLngBounds bounds;

  const Relation({
    required super.id,
    required this.bounds,
    required super.tags,
  });

  @override
  String toString() => 'Relation $id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Way &&
          id == other.id &&
          bounds == other.bounds &&
          const DeepCollectionEquality().equals(tags, other.tags));

  @override
  int get hashCode => Object.hash(id, bounds, tags);
}
