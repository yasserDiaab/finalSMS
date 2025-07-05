import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pro/services/signalr_service.dart';
import 'package:pro/models/LocationNotificationModel.dart';
import 'dart:async';

class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({Key? key}) : super(key: key);

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  LocationNotificationModel? currentLocation;
  late final StreamSubscription<LocationNotificationModel> _locationSub;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _locationSub = SignalRService.instance.locationStream.listen((location) {
      print('📍 LiveTrackingMap received: lat=[1m${location.latitude}[0m, lng=[1m${location.longitude}[0m');
      setState(() {
        currentLocation = location;
      });
      // حرك الخريطة للحدثيات الجديدة
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        _mapController.camera.zoom,
      );
    });
  }

  @override
  void dispose() {
    _locationSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation != null) {
      print('📍 Building marker at: ${currentLocation!.latitude}, ${currentLocation!.longitude}');
    }
    return SizedBox(
      height: 300,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: currentLocation != null
              ? LatLng(currentLocation!.latitude, currentLocation!.longitude)
              : LatLng(0, 0),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          if (currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: LatLng(currentLocation!.latitude, currentLocation!.longitude),
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
        ],
      ),
    );
  }
}