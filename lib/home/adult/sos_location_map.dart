import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/widgets/header_profile.dart';

class SosLocationMapScreen extends StatefulWidget {
  final SosNotificationModel notification;

  const SosLocationMapScreen({
    super.key,
    required this.notification,
  });

  @override
  State<SosLocationMapScreen> createState() => _SosLocationMapScreenState();
}

class _SosLocationMapScreenState extends State<SosLocationMapScreen> {
  final MapController _mapController = MapController();
  late LatLng _sosLocation;
  String _userType = 'traveler'; // Default to traveler

  @override
  void initState() {
    super.initState();

    print('MAP SCREEN: lat=${widget.notification.latitude}, lng=${widget.notification.longitude}');
    log('📍 SosLocationMapScreen - Received Lat: ${widget.notification.latitude}, Lng: ${widget.notification.longitude}');
    _sosLocation = LatLng(
      widget.notification.latitude,
      widget.notification.longitude,
    );

    log('📍 Map screen initialized with:');
  log('- Latitude: ${widget.notification.latitude}');
  log('- Longitude: ${widget.notification.longitude}');

    // Determine user type from cache
    final adultType = CacheHelper.getData(key: 'adultType');
    if (adultType != null) {
      _userType = adultType.toString().toLowerCase() == 'supporter'
          ? 'supporter'
          : 'traveler';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xff193869)),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: HeaderProfile(
                      showNotifications: false,
                      userType: _userType,
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOS: ${widget.notification.travelerName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff193869),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          widget.notification.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Location coordinates
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed,
                        color: Color(0xff193869), size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Lat: ${widget.notification.latitude.toStringAsFixed(6)}, Lng: ${widget.notification.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Map
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _sosLocation,
                      initialZoom: 15,
                    ),
                    children: [
                      // Base map layer
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),

                      // SOS location marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _sosLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Map control buttons
            Positioned(
              bottom: 80,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom in button
                    IconButton(
                      icon: const Icon(Icons.add,
                          color: Color(0xff193869), size: 20),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_sosLocation, currentZoom + 1);
                      },
                    ),
                    // Zoom out button
                    IconButton(
                      icon: const Icon(Icons.remove,
                          color: Color(0xff193869), size: 20),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_sosLocation, currentZoom - 1);
                      },
                    ),
                    // Center on SOS location
                    IconButton(
                      icon: const Icon(Icons.my_location,
                          color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () {
                        _mapController.move(_sosLocation, 15);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Open navigation in OpenStreetMap
                        _openExternalMap();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff193869),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions, size: 14),
                          SizedBox(width: 4),
                          Text('Navigate', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Call the traveler
                        _showCallDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, size: 14),
                          SizedBox(width: 4),
                          Text('Call', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExternalMap() async {
    final lat = widget.notification.latitude;
    final lng = widget.notification.longitude;
    final url = 'https://www.openstreetmap.org/directions?from=&to=$lat%2C$lng';

    // Show dialog with the URL
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('External Navigation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Open in external map application:'),
            const SizedBox(height: 10),
            Text(
              'Latitude: $lat\nLongitude: $lng',
              style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 10),
            Text(
              'URL: $url',
              style: const TextStyle(fontSize: 10, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Traveler'),
        content: const Text(
            'This would initiate a call to the traveler. Phone number not available in this demo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
