import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:pro/widgets/live_tracking_map.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Location _locationService = Location();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];
  StreamSubscription<LocationData>? _locationSubscription;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!await _checkAndRequestPermissions()) return;

    _locationSubscription = _locationService.onLocationChanged.listen(
      (LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          setState(() {
            _currentLocation =
                LatLng(locationData.latitude!, locationData.longitude!);
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<bool> _checkAndRequestPermissions() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _fetchCoordinates(String location) async {
    if (location.isEmpty) return;

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        setState(() {
          _destination = LatLng(lat, lon);
        });
        await _fetchRoute();
      } else {
        _showError('الموقع غير موجود. حاول مرة أخرى.');
      }
    } else {
      _showError('فشل في جلب الموقع. حاول لاحقًا.');
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry'];
      final routePolyline = _decodePolyline(geometry);
      setState(() {
        _route =
            routePolyline.map((point) => LatLng(point[0], point[1])).toList();
      });
    } else {
      _showError('فشل في جلب المسار. حاول لاحقًا.');
    }
  }

  List<List<double>> _decodePolyline(String polyline) {
    const factor = 1e5;
    List<List<double>> points = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lon = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;
      shift = 0;
      result = 0;

      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lon += dlng;
      points.add([lat / factor, lon / factor]);
    }
    return points;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffebeeef),
      body: Column(
        children: [
          const SizedBox(
            height: 40,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xff193869),
                  width: 2.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        fillColor: Color(0xff193869),
                        focusColor: Color(0xff193869),
                        hintText: 'أدخل الموقع',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final location = _locationController.text.trim();
                      if (location.isNotEmpty) {
                        _fetchCoordinates(location);
                      }
                    },
                    icon: const Icon(
                      Icons.search,
                      color: Color(0xff193869),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const LiveTrackingMap(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation ?? const LatLng(0, 0),
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          ),
                          CurrentLocationLayer(
                            style: const LocationMarkerStyle(
                              marker: DefaultLocationMarker(
                                child: Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                ),
                              ),
                              markerSize: Size(40, 40),
                            ),
                            alignPositionOnUpdate: null,
                            alignDirectionOnUpdate: null,
                          ),
                          if (_destination != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _destination!,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Color(0xff193869),
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          if (_route.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _route,
                                  strokeWidth: 4.0,
                                  color: const Color(0xff193869),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: FloatingActionButton(
                          backgroundColor: const Color(0xff193869),
                          onPressed: () {
                            if (_currentLocation != null) {
                              _mapController.move(_currentLocation!, 15);
                            }
                          },
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xffebeeef),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
