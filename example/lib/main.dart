import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_query_osm_features/flutter_map_query_osm_features.dart'
    hide LatLngBounds;
import 'package:latlong2/latlong.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FMQOF Demo',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: Colors.red,
          switchTheme: SwitchThemeData(
            thumbIcon: MaterialStateProperty.resolveWith(
              (states) => Icon(
                states.contains(MaterialState.selected)
                    ? Icons.check
                    : Icons.close,
              ),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isLoading = false;

  Iterable<OSMElement>? osmNearby;
  Iterable<OSMElement>? osmEnclosed;

  LatLng? hoveredNode;
  List<LatLng>? hoveredWay;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('FMQOF Demo')),
        body: Row(
          children: [
            Flexible(
              flex: 3,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(51.509364, -0.128928),
                  initialZoom: 9.2,
                  onTap: (_, pos) async {
                    setState(() {
                      isLoading = true;
                      osmEnclosed = osmNearby = null;
                    });

                    final osmElements = await QueryFeatures()
                        .getElements(radius: 20, point: pos);

                    setState(() {
                      osmNearby = osmElements.nearby;
                      osmEnclosed = osmElements.enclosing;
                      isLoading = false;
                    });
                  },
                ),
                nonRotatedChildren: const [
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                    maxZoom: double.infinity,
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 20,
                        height: 20,
                        point: hoveredNode ?? const LatLng(0, 0),
                        builder: (context) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.5),
                            border: Border.all(color: Colors.purple, width: 2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hoveredWay != null)
                    hoveredWay!.first != hoveredWay!.last
                        ? PolylineLayer(
                            polylines: [
                              Polyline(
                                points: hoveredWay ?? [],
                                color: Colors.purple,
                                strokeWidth: 5,
                              ),
                            ],
                          )
                        : PolygonLayer(
                            polygons: [
                              Polygon(
                                points: hoveredWay ?? [],
                                color: Colors.purple.withOpacity(0.5),
                                borderColor: Colors.purple,
                                borderStrokeWidth: 5,
                                isFilled: true,
                              ),
                            ],
                          ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Nearby Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox.square(dimension: 12),
                    if (osmNearby != null) ...[
                      Expanded(
                        child: ListView.builder(
                          itemCount: osmNearby!.length,
                          itemBuilder: (context, index) {
                            final nearby = osmNearby!.elementAt(index);
                            return MouseRegion(
                              onEnter: switch (nearby) {
                                Node() => (_) =>
                                    setState(() => hoveredNode = nearby.coord),
                                FullWay() => (_) =>
                                    setState(() => hoveredWay = nearby.coords),
                                Relation() => (_) {
                                    final bounds = LatLngBounds(
                                      nearby.bounds.$1,
                                      nearby.bounds.$2,
                                    );
                                    setState(
                                      () => hoveredWay = [
                                        bounds.northWest,
                                        bounds.northEast,
                                        bounds.southEast,
                                        bounds.southWest,
                                        bounds.northWest,
                                      ],
                                    );
                                  },
                                _ => null,
                              },
                              onExit: (_) => setState(
                                () => hoveredWay = hoveredNode = null,
                              ),
                              child: ListTile(
                                leading: switch (nearby) {
                                  Node() => const Icon(Icons.place_outlined),
                                  Way() => const Icon(Icons.polyline_rounded),
                                  Relation() => const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.hub_outlined),
                                        SizedBox.square(dimension: 6),
                                        Icon(Icons.flaky, color: Colors.amber),
                                      ],
                                    ),
                                },
                                title: nearby.tags?['name'] == null &&
                                        nearby.tags?['ref'] == null
                                    ? Text(nearby.id.toString())
                                    : Text(
                                        nearby.tags?['name'] == null
                                            ? '${nearby.tags?['ref']}'
                                            : nearby.tags?['ref'] == null
                                                ? '${nearby.tags?['name']}'
                                                : '${nearby.tags?['name']} (${nearby.tags?['ref']})',
                                      ),
                                subtitle: nearby.tags?['name'] == null &&
                                        nearby.tags?['ref'] == null
                                    ? null
                                    : Text(nearby.id.toString()),
                                dense: true,
                                onTap: nearby is Relation ? () {} : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ] else if (isLoading)
                      const CircularProgressIndicator.adaptive()
                    else
                      const Icon(Icons.ads_click, size: 42),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Enclosing Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox.square(dimension: 12),
                    if (osmEnclosed != null) ...[
                      Expanded(
                        child: ListView.builder(
                          itemCount: osmEnclosed!.length,
                          itemBuilder: (context, index) {
                            final enclosed = osmEnclosed!.elementAt(index);
                            return MouseRegion(
                              onEnter: switch (enclosed) {
                                FullWay() => (_) => setState(
                                    () => hoveredWay = enclosed.coords),
                                PartialWay() => (_) {
                                    final bounds = LatLngBounds(
                                      enclosed.bounds.$1,
                                      enclosed.bounds.$2,
                                    );
                                    setState(
                                      () => hoveredWay = [
                                        bounds.northWest,
                                        bounds.northEast,
                                        bounds.southEast,
                                        bounds.southWest,
                                        bounds.northWest,
                                      ],
                                    );
                                  },
                                _ => null,
                              },
                              onExit: (_) => setState(
                                () => hoveredWay = hoveredNode = null,
                              ),
                              child: ListTile(
                                leading: switch (enclosed) {
                                  Node() => null,
                                  FullWay() =>
                                    const Icon(Icons.polyline_rounded),
                                  PartialWay() => const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.polyline_rounded),
                                        SizedBox.square(dimension: 6),
                                        Icon(Icons.flaky, color: Colors.amber),
                                      ],
                                    ),
                                  Relation() => const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.hub_outlined),
                                        SizedBox.square(dimension: 6),
                                        Icon(Icons.flaky, color: Colors.amber),
                                      ],
                                    ),
                                },
                                title: enclosed.tags?['name'] == null &&
                                        enclosed.tags?['ref'] == null
                                    ? Text(enclosed.id.toString())
                                    : Text(
                                        enclosed.tags?['name'] == null
                                            ? '${enclosed.tags?['ref']}'
                                            : enclosed.tags?['ref'] == null
                                                ? '${enclosed.tags?['name']}'
                                                : '${enclosed.tags?['name']} (${enclosed.tags?['ref']})',
                                      ),
                                subtitle: enclosed.tags?['name'] == null &&
                                        enclosed.tags?['ref'] == null
                                    ? null
                                    : Text(enclosed.id.toString()),
                                dense: true,
                                onTap: enclosed is PartialWay
                                    ? () async {
                                        final osmEnclosedList =
                                            osmEnclosed!.toList();
                                        final index =
                                            osmEnclosedList.indexWhere(
                                                (e) => e.id == enclosed.id);
                                        osmEnclosedList
                                          ..removeAt(index)
                                          ..insert(
                                            index,
                                            await enclosed.getFullData(),
                                          );
                                        setState(
                                          () => osmEnclosed = osmEnclosedList,
                                        );
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ] else if (isLoading)
                      const CircularProgressIndicator.adaptive()
                    else
                      const Icon(Icons.ads_click, size: 42),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
