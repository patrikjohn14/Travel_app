import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:maps_tracker/settings.dart';

class EnhancedRouteMapScreen extends StatefulWidget {
  final String? endPointString;

  const EnhancedRouteMapScreen({super.key, this.endPointString});

  @override
  State<EnhancedRouteMapScreen> createState() => _EnhancedRouteMapScreenState();
}

class _EnhancedRouteMapScreenState extends State<EnhancedRouteMapScreen> {
  final MapController _mapController = MapController();
  final LatLng startPoint = const LatLng(
    35.349961,
    1.32057120,
  ); // Computer Science Faculty
  late LatLng endPoint;

  // Tiaret landmarks with coordinates
  final List<Map<String, dynamic>> tiaretLandmarks = [
    {
      'name': 'Rader Forest',
      'position': const LatLng(35.4500, 1.5500),
      'description': 'Beautiful natural forest area in Tiaret',
    },
    {
      'name': 'El Djadar Wall',
      'position': const LatLng(35.3800, 1.3200),
      'description': 'Historic defensive wall structure',
    },
    {
      'name': 'Ibn Khaldoun Cave',
      'position': const LatLng(35.01935385, 1.06675217),
      'description': 'Historical cave associated with Ibn Khaldoun',
    },
    {
      'name': 'National Horse Breeding Center',
      'position': const LatLng(35.4000, 1.2500),
      'description': 'Prestigious horse breeding facility',
    },
    {
      'name': 'Yasdi Waterfall',
      'position': const LatLng(35.5000, 1.6000),
      'description': 'Scenic waterfall in the Tiaret region',
    },
  ];

  // Route data
  List<LatLng> primaryRoute = [];
  List<LatLng> alternativeRoute = [];
  List<dynamic> routeInstructions = [];
  String? selectedLandmark;
  String? routeAlertMessage;
  String? repairEstimate;
  Map<String, dynamic>? damageDetails;

  // UI state
  bool isLoading = true;
  bool showAlternative = false;
  bool isSelectingMode = false;
  bool showTraffic = false;
  bool showLandmarks = true;
  bool hasRouteAlert = false;
  bool calculatingAlternative = false;

  // Map metrics
  double zoom = 13.0;
  double primaryDistance = 0.0;
  double primaryDuration = 0.0;
  double alternativeDistance = 0.0;
  double alternativeDuration = 0.0;
  final String apiUrl = Settings.apiBaseUrl;

  @override
  @override
  void initState() {
    super.initState();
    if (widget.endPointString != null) {
      _parseEndPoint();
      print("EndPoint = $endPoint");
      _checkForRouteAlerts();
    } else {
      setState(() {
        endPoint = startPoint;
        isLoading = false;
        isSelectingMode = true;
      });
    }
  }

  void _parseEndPoint() {
    try {
      final parts = widget.endPointString!.split(',');
      if (parts.length == 2) {
        endPoint = LatLng(double.parse(parts[0]), double.parse(parts[1]));
      } else {
        throw Exception('Invalid coordinate format');
      }
    } catch (e) {
      endPoint = startPoint;
    }
  }

  Future<void> _checkForRouteAlerts() async {
    setState(() => isLoading = true);

    try {
      final alertResponse = await http.get(
        Uri.parse(
          '$apiUrl/api/alerts/check?lat=${endPoint.latitude}&lng=${endPoint.longitude}',
        ),
      );

      if (alertResponse.statusCode == 200) {
        final alertData = jsonDecode(alertResponse.body);

        if (alertData['hasAlert'] == true) {
          final alert = alertData['alert'];
          damageDetails = alert['details'];

          final osrmAltRoute = await getAlternativeRoute(startPoint, endPoint);

          setState(() {
            alternativeRoute = osrmAltRoute;
            routeAlertMessage = alert['title'];
            repairEstimate = alert['expires_at'];
            hasRouteAlert = true;
            showAlternative = true;
            alternativeDistance = _calculateRouteDistance(alternativeRoute);
            alternativeDuration = _calculateRouteDuration(alternativeDistance);
          });

          _centerMap(alternativeRoute);
        } else {
          print('No road damage alerts found');
          await _getPrimaryRouteData();
        }
      } else {
        print('Alert check failed with status: ${alertResponse.statusCode}');
        await _getPrimaryRouteData();
      }
    } catch (e) {
      print('!!! ERROR FETCHING ROUTE ALERTS !!!\n$e');
      setState(() {
        primaryRoute = _generateDetailedRoute(startPoint, endPoint);
        primaryDistance = _calculateRouteDistance(primaryRoute);
        primaryDuration = _calculateRouteDuration(primaryDistance);
      });
      _centerMap(primaryRoute);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<List<LatLng>> getAlternativeRoute(LatLng start, LatLng end) async {
    final midLat = (start.latitude + end.latitude) / 2 + 0.01;
    final midLng = (start.longitude + end.longitude) / 2 + 0.01;
    final via = LatLng(midLat, midLng);

    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${via.longitude},${via.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      return coords.map((c) => LatLng(c[1], c[0])).toList(); // [lng, lat]
    } else {
      throw Exception('Failed to fetch alternative route');
    }
  }

  Future<void> _getPrimaryRouteData() async {
    try {
      // Get primary route coordinates from backend API
      final routeResponse = await http.get(
        Uri.parse(
          '$apiUrl/api/routes'
          '?startLat=${startPoint.latitude}'
          '&startLng=${startPoint.longitude}'
          '&endLat=${endPoint.latitude}'
          '&endLng=${endPoint.longitude}',
        ),
      );

      if (routeResponse.statusCode == 200) {
        final routeData = jsonDecode(routeResponse.body);
        print('=== PRIMARY ROUTE DATA ===\n$routeData');

        setState(() {
          final coords =
              routeData['data']['primaryRoute']['coordinates'] as List;
          primaryRoute =
              coords.map((coord) => LatLng(coord[1], coord[0])).toList();

          primaryDistance =
              (routeData['data']['primaryRoute']['distanceKm'] ?? 0).toDouble();
          primaryDuration =
              (routeData['data']['primaryRoute']['durationMin'] ?? 0)
                  .toDouble();

          routeInstructions =
              routeData['data']['primaryRoute']['instructions'] ?? [];
        });

        print("Primary route length = ${primaryRoute.length}");

        _centerMap(primaryRoute);
      } else {
        print(
          'Primary route request failed with status: ${routeResponse.statusCode}',
        );
        _fallbackToGeneratedRoute();
      }
    } catch (e) {
      print('!!! ERROR FETCHING PRIMARY ROUTE !!!\n$e');
      _fallbackToGeneratedRoute();
    }
  }

  void _fallbackToGeneratedRoute() {
    setState(() {
      primaryRoute = _generateDetailedRoute(startPoint, endPoint);
      primaryDistance = _calculateRouteDistance(primaryRoute);
      primaryDuration = _calculateRouteDuration(primaryDistance);
    });
    print("Fallback primary route length = ${primaryRoute.length}");
    _centerMap(primaryRoute);
  }

  List<LatLng> _generateDetailedRoute(LatLng start, LatLng end) {
    // Generate a more realistic route with intermediate points
    print('Generating fallback detailed route');
    return [
      start,
      LatLng(
        start.latitude + (end.latitude - start.latitude) * 0.3,
        start.longitude + (end.longitude - start.longitude) * 0.3,
      ),
      LatLng(
        start.latitude + (end.latitude - start.latitude) * 0.5,
        start.longitude + (end.longitude - start.longitude) * 0.5,
      ),
      LatLng(
        start.latitude + (end.latitude - start.latitude) * 0.7,
        start.longitude + (end.longitude - start.longitude) * 0.7,
      ),
      end,
    ];
  }

  void _centerMap(List<LatLng> route) {
    if (route.isEmpty) return;

    double avgLat = 0;
    double avgLng = 0;

    for (var point in route) {
      avgLat += point.latitude;
      avgLng += point.longitude;
    }

    final center = LatLng(avgLat / route.length, avgLng / route.length);

    _mapController.move(center, 13);
  }

  double _calculateRouteDistance(List<LatLng> route) {
    final distance = Distance();
    double total = 0;
    for (int i = 0; i < route.length - 1; i++) {
      total += distance(route[i], route[i + 1]);
    }
    return total / 1000; // Convert to kilometers
  }

  double _calculateRouteDuration(double distance) {
    // Average speed of 50 km/h for estimation
    return (distance / 50) * 60; // Convert to minutes
  }

  void _toggleRouteDisplay() {
    setState(() => showAlternative = !showAlternative);
    _centerMap(showAlternative ? alternativeRoute : primaryRoute);
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectingMode = !isSelectingMode;
      if (isSelectingMode) showAlternative = false;
    });
  }

  void _showAlertDetails() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Route Alert',
              style: TextStyle(color: Colors.red),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeAlertMessage!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (damageDetails != null) ...[
                    const Text(
                      'Damage Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'title: ${damageDetails!['title']}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Severity: ${damageDetails!['expires_at']}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Estimated repair time: $repairEstimate',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alternative route has been automatically selected.',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
    );
  }

  void _showLandmarkDetails(Map<String, dynamic> landmark) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(landmark['name']),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(landmark['description']),
                  const SizedBox(height: 16),
                  Text(
                    'Coordinates: ${landmark['position'].latitude.toStringAsFixed(6)}, '
                    '${landmark['position'].longitude.toStringAsFixed(6)}',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    endPoint = landmark['position'];
                    isLoading = true;
                  });
                  _checkForRouteAlerts();
                  Navigator.pop(ctx);
                },
                child: const Text('Set as Destination'),
              ),
            ],
          ),
    );
  }

  void _showRouteInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        showAlternative ? 'Alternative Route' : 'Primary Route',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        '${(showAlternative ? alternativeDistance : primaryDistance).toStringAsFixed(2)} km • '
                        '${(showAlternative ? alternativeDuration : primaryDuration).toStringAsFixed(0)} min',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Step-by-step directions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: routeInstructions.length,
                        itemBuilder: (_, index) {
                          final step = routeInstructions[index];
                          final action = step['action'] ?? step['type'] ?? '';
                          final modifier = step['modifier'] ?? '';
                          final name = step['name'] ?? 'Unnamed road';
                          final distance = (step['distance'] ?? 0).toDouble();
                          final duration = (step['duration'] ?? 0).toDouble();

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                leading: _getDirectionIcon(action, modifier),
                                title: Text(
                                  _formatInstruction(action, modifier),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '$name\n${distance.toStringAsFixed(1)} km • ${duration.toStringAsFixed(1)} min',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _getDirectionIcon(String action, String modifier) {
    switch (action) {
      case 'turn':
        switch (modifier) {
          case 'left':
            return const Icon(Icons.turn_left, color: Colors.blue);
          case 'right':
            return const Icon(Icons.turn_right, color: Colors.blue);
          case 'sharp left':
            return const Icon(Icons.u_turn_left, color: Colors.blue);
          case 'sharp right':
            return const Icon(Icons.u_turn_right, color: Colors.blue);
          default:
            return const Icon(Icons.swap_horiz, color: Colors.blue);
        }
      case 'depart':
        return const Icon(Icons.flag, color: Colors.green);
      case 'arrive':
        return const Icon(Icons.location_on, color: Colors.red);
      case 'continue':
        return const Icon(Icons.straight, color: Colors.blue);
      default:
        return const Icon(Icons.directions, color: Colors.blue);
    }
  }

  String _formatInstruction(String action, String modifier) {
    switch (action) {
      case 'turn':
        switch (modifier) {
          case 'left':
            return 'Turn left';
          case 'right':
            return 'Turn right';
          case 'sharp left':
            return 'Sharp left turn';
          case 'sharp right':
            return 'Sharp right turn';
          case 'slight left':
            return 'Slight left turn';
          case 'slight right':
            return 'Slight right turn';
          default:
            return 'Turn';
        }
      case 'depart':
        return 'Start your journey';
      case 'arrive':
        return 'Arrive at destination';
      case 'continue':
        return 'Continue straight';
      case 'merge':
        return 'Merge onto road';
      case 'roundabout':
        return 'Take roundabout';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: startPoint,
              initialZoom: zoom,
              onTap: (_, point) {
                if (isSelectingMode) {
                  setState(() {
                    endPoint = point;
                    isLoading = true;
                  });
                  _checkForRouteAlerts();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (showTraffic)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: [
                        const LatLng(35.3500, 1.3250),
                        const LatLng(35.3550, 1.3300),
                        const LatLng(35.3600, 1.3200),
                      ],
                      color: Colors.orange.withOpacity(0.3),
                      borderColor: Colors.red,
                    ),
                  ],
                ),
              if (showLandmarks)
                MarkerLayer(
                  markers:
                      tiaretLandmarks
                          .map(
                            (landmark) => Marker(
                              point: landmark['position'],
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showLandmarkDetails(landmark),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              // Enhanced PolylineLayer with better visualization
              PolylineLayer(
                polylines: [
                  if (showAlternative && alternativeRoute.isNotEmpty)
                    Polyline(
                      points: alternativeRoute,
                      color: Colors.green.withOpacity(0.7),
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    )
                  else if (primaryRoute.isNotEmpty)
                    Polyline(
                      points: primaryRoute,
                      color: Colors.blue.withOpacity(0.7),
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: startPoint,
                    width: 80,
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: Colors.green,
                          size: 40,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Start',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Marker(
                    point: endPoint,
                    width: 80,
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'End',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (calculatingAlternative)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Calculating alternative route...'),
                ],
              ),
            ),
          if (!isSelectingMode)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        showAlternative ? 'ALTERNATIVE ROUTE' : 'PRIMARY ROUTE',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        showAlternative
                            ? '${alternativeDistance.toStringAsFixed(1)} km • ${alternativeDuration.toStringAsFixed(0)} min'
                            : '${primaryDistance.toStringAsFixed(1)} km • ${primaryDuration.toStringAsFixed(0)} min',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (hasRouteAlert && showAlternative) ...[
                        const SizedBox(height: 8),
                        Text(
                          '⚠️ Route alert: $routeAlertMessage',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (isSelectingMode)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withOpacity(0.7),
                child: const Text(
                  'Tap on map to select destination',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            onPressed:
                () => setState(() {
                  zoom += 1;
                  _mapController.move(_mapController.camera.center, zoom);
                }),
            mini: true,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOut',
            onPressed:
                () => setState(() {
                  zoom -= 1;
                  _mapController.move(_mapController.camera.center, zoom);
                }),
            mini: true,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _toggleSelectionMode,
            backgroundColor: isSelectingMode ? Colors.red : Colors.blue,
            child: Icon(
              isSelectingMode ? Icons.done : Icons.edit_location,
              color: Colors.white,
            ),
          ),
          if (!isSelectingMode && !hasRouteAlert) const SizedBox(height: 16),
        ],
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(isSelectingMode ? 'Select Destination' : 'Route Navigation'),
      actions: [
        if (hasRouteAlert)
          IconButton(
            icon: const Icon(Icons.warning, color: Colors.red),
            onPressed: _showAlertDetails,
            tooltip: 'Route Alert',
          ),
        IconButton(
          icon: Icon(showTraffic ? Icons.traffic : Icons.traffic_outlined),
          onPressed: () => setState(() => showTraffic = !showTraffic),
          tooltip: 'Traffic Info',
        ),
        IconButton(
          icon: Icon(
            showLandmarks ? Icons.landscape : Icons.landscape_outlined,
          ),
          onPressed: () => setState(() => showLandmarks = !showLandmarks),
          tooltip: 'Landmarks',
        ),
        if (!isSelectingMode) ...[
          if (hasRouteAlert || alternativeRoute.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.alt_route,
                color: showAlternative ? Colors.green : Colors.grey,
              ),
              onPressed: _toggleRouteDisplay,
              tooltip: 'Toggle Route',
            ),
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: _showRouteInstructions,
            tooltip: 'Route Instructions',
          ),
        ],
      ],
    );
  }
}
