import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class NearbyPlacesMap extends StatefulWidget {
  final String placeType;

  const NearbyPlacesMap({Key? key, required this.placeType}) : super(key: key);

  @override
  State<NearbyPlacesMap> createState() => _NearbyPlacesMapState();
}

class _NearbyPlacesMapState extends State<NearbyPlacesMap> {
  LatLng? _currentLocation;
  List<LatLng> _places = [];

  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  Future<void> _initLocationAndFetch() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }

    if (permissionGranted == PermissionStatus.granted) {
      final locationData = await _location.getLocation();
      final current = LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentLocation = current;
      });
      _fetchNearby(widget.placeType, current);
    }
  }

  Future<void> _fetchNearby(String keyword, LatLng location) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search.php?q=$keyword+near+${location.latitude},${location.longitude}&format=jsonv2');

    final response =
        await http.get(url, headers: {'User-Agent': 'Flutter App'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<LatLng> fetched = [];

      for (var place in data) {
        final lat = double.tryParse(place['lat']);
        final lon = double.tryParse(place['lon']);
        if (lat != null && lon != null) {
          fetched.add(LatLng(lat, lon));
        }
      }

      setState(() {
        _places = fetched;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby ${widget.placeType}'),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: _currentLocation!,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                    ..._places.map((p) => Marker(
                          width: 40,
                          height: 40,
                          point: p,
                          child:
                              const Icon(Icons.location_on, color: Colors.red),
                        )),
                  ],
                ),
              ],
            ),
    );
  }
}
