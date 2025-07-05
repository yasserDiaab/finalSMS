import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/cubit/sos/sos_cubit.dart';
import 'package:pro/cubit/sos/sos_state.dart';
import 'package:pro/home/adult/location_map.dart';
import 'package:pro/home/adult/profile_page.dart';
import 'package:pro/home/adult/settings_page_supporter.dart';
import 'package:pro/home/adult/supporter_menu_list.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/models/TripNotificationModel.dart';
import 'package:pro/services/notification_service.dart';
import 'package:pro/services/signalr_service.dart';
import 'package:pro/widgets/custom_bottom_bar.dart';
import 'package:pro/widgets/header_profile.dart';
import 'package:pro/widgets/notification_icon.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pro/models/LocationNotificationModel.dart';
import 'package:pro/home/adult/offline_phones_screen.dart';

class Supporter extends StatefulWidget {
  const Supporter({super.key});

  @override
  State<Supporter> createState() => _TravelerState();
}

class _TravelerState extends State<Supporter> {
  int currentIndex = 0; // لمتابعة العنصر النشط في BottomNavigationBar

  // Pages that can be changed later to real pages
  final List<Widget> pages = [
    const HomePage(), // Home page with new design
    SettingsScreen2(),
    MapScreen(),
    SupportersListWidget(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize notification service
    getIt<NotificationService>().initialize();

    // SignalR connection is already initialized in main.dart, no need to initialize again
    debugPrint("✅ Supporter page initialized");
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final sosCubit = getIt<SosCubit>();
        sosCubit.initialize();
        // Set context for showing dialogs
        sosCubit.setContext(context);
        return sosCubit;
      },
      child: BlocListener<SosCubit, SosState>(
        listener: (context, state) {
          if (state is SosNotificationReceived) {
            // Show a snackbar when a notification is received
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('SOS Alert from ${state.notification.travelerName}!'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    getIt<NotificationService>()
                        .showSosDialog(context, state.notification);
                  },
                ),
              ),
            );
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false, // Prevent overlap with keyboard
          body: pages[currentIndex], // Display page based on currentIndex
          bottomNavigationBar: CustomBottomBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            icons: bottomBarIcons,
          ),
        ),
      ),
    );
  }
}

final List<IconData> bottomBarIcons = [
  Icons.home,
  Icons.settings,
  Icons.location_on_outlined,
  Icons.menu,
  Icons.person,
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TripNotificationModel> activeTrips = [];
  final NotificationService _notificationService = getIt<NotificationService>();

  @override
  void initState() {
    super.initState();
    _setupTripNotifications();
  }

  void _setupTripNotifications() {
    debugPrint('🔍 Setting up trip notifications...');

    // Listen for trip start notifications
    _notificationService.onTripStartReceived = (TripNotificationModel trip) {
      print('🔔 [DEBUG] Supporter received TripNotificationModel:');
      print('    - travelerName: ${trip.travelerName}');
      print('    - tripId: ${trip.tripId}');
      print('    - status: ${trip.status}');
      print('    - action: ${trip.action}');
      print('    - startTime: ${trip.startTime}');

      // Check if data is valid
      if (trip.travelerName.isEmpty) {
        debugPrint('⚠️ Warning: TravelerName is empty in callback!');
      }
      if (trip.tripId.isEmpty) {
        debugPrint('⚠️ Warning: TripId is empty in callback!');
      }
      if (trip.startTime.isEmpty) {
        debugPrint('⚠️ Warning: StartTime is empty in callback!');
      }

      setState(() {
        // Add new trip to active trips list
        activeTrips.add(trip);
        debugPrint(
            '✅ Trip added to activeTrips. Total trips: ${activeTrips.length}');
      });

      // Show notification
      final displayName =
          trip.travelerName.isNotEmpty ? trip.travelerName : 'Unknown Traveler';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName started a new trip!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    };

    debugPrint('✅ Trip start callback set successfully');

    // Listen for trip end notifications from SignalR
    getIt<SignalRService>().tripEventsStream.listen((event) {
      debugPrint('🔍 Received trip event: ${event['event']}');
      if (event['event'] == 'TripEnded') {
        final data = event['data'] as Map<String, dynamic>;
        final tripId =
            data['TripId']?.toString() ?? data['tripId']?.toString() ?? '';

        debugPrint('🔍 Supporter received trip end notification:');
        debugPrint('  - TripId: $tripId');
        debugPrint('  - Raw data: $data');

        setState(() {
          // Remove the ended trip from active trips
          final initialCount = activeTrips.length;
          activeTrips.removeWhere((trip) => trip.tripId == tripId);
          final finalCount = activeTrips.length;
          debugPrint(
              '✅ Trip removed from activeTrips. Before: $initialCount, After: $finalCount');
        });

        // Show notification
        final travelerName = data['TravelerName']?.toString() ??
            data['travelerName']?.toString() ??
            'Traveler';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$travelerName ended their trip'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    debugPrint('✅ Trip end listener set successfully');
  }

  void onMapTap() {
    // Action when map is tapped
    debugPrint('Map tapped!');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const HeaderProfile(showNotifications: true, userType: 'supporter'),
            const SizedBox(height: 20),

            // زر أرقام الهواتف المحفوظة
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfflinePhonesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text(
                  'أرقام الهواتف المحفوظة',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF30C988),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Display active trips from notifications
            ...activeTrips.map((trip) {
              debugPrint('🔍 Building MapCard for trip:');
              debugPrint('  - TripId: ${trip.tripId}');
              debugPrint('  - TravelerId: ${trip.travelerId}');
              debugPrint('  - TravelerName: ${trip.travelerName}');
              debugPrint('  - StartTime: ${trip.startTime}');
              debugPrint('  - Formatted date: ${_formatDate(trip.startTime)}');
              debugPrint('  - Formatted time: ${_formatTime(trip.startTime)}');

              // Use fallback values if data is empty
              final displayName = trip.travelerName.isNotEmpty
                  ? trip.travelerName
                  : 'Unknown Traveler';
              final displayDate = _formatDate(trip.startTime);
              final displayTime = _formatTime(trip.startTime);

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: MapCard(
                  name: displayName,
                  status: 'Active',
                  date: displayDate,
                  time: displayTime,
                  address:
                      'Trip in progress', // You can update this with actual location
                  isActive: true,
                  onMapTap: onMapTap,
                  tripId: trip.tripId,
                  onRemove: () {
                    setState(() {
                      activeTrips.removeWhere((t) => t.tripId == trip.tripId);
                    });
                  },
                ),
              );
            }).toList(),

            // Show message if no active trips
            if (activeTrips.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No active trips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'You will see active trips here when travelers start their journeys',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'Poppins',
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

  String _formatDate(String startTime) {
    debugPrint('🔍 _formatDate called with: $startTime');

    // Handle empty or null startTime
    if (startTime.isEmpty || startTime.trim().isEmpty) {
      debugPrint('⚠️ _formatDate: Empty startTime, returning current date');
      final now = DateTime.now();
      return '${now.day}/${now.month}/${now.year}';
    }

    try {
      final date = DateTime.parse(startTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      String result;
      if (difference.inDays == 0) {
        // Same day - show the actual date instead of "Today"
        result = '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays == 1) {
        result = 'Yesterday';
      } else {
        result = '${date.day}/${date.month}/${date.year}';
      }

      debugPrint('🔍 _formatDate result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ _formatDate error: $e');
      final now = DateTime.now();
      return '${now.day}/${now.month}/${now.year}';
    }
  }

  String _formatTime(String startTime) {
    debugPrint('🔍 _formatTime called with: $startTime');

    // Handle empty or null startTime
    if (startTime.isEmpty || startTime.trim().isEmpty) {
      debugPrint('⚠️ _formatTime: Empty startTime, returning current time');
      final now = DateTime.now();
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }

    try {
      final date = DateTime.parse(startTime);
      final result =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      debugPrint('🔍 _formatTime result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ _formatTime error: $e');
      final now = DateTime.now();
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
  }
}

class MapCard extends StatelessWidget {
  final String name;
  final String status;
  final String date;
  final String time;
  final String address;
  final bool isActive;
  final VoidCallback onMapTap;
  final String? tripId;
  final VoidCallback? onRemove;

  const MapCard({
    Key? key,
    required this.name,
    required this.status,
    required this.date,
    required this.time,
    required this.address,
    required this.isActive,
    required this.onMapTap,
    this.tripId,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 MapCard build called with:');
    debugPrint('  - name: $name');
    debugPrint('  - status: $status');
    debugPrint('  - date: $date');
    debugPrint('  - time: $time');
    debugPrint('  - address: $address');
    debugPrint('  - isActive: $isActive');
    debugPrint('  - tripId: $tripId');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green
            : Colors.grey[400], // اللون حسب النشاط في الكونتينر الكبير
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 25,
              backgroundImage:
                  AssetImage('assets/images/man.jpeg'), // صورة شخصية
            ),
            title: Text(
              name,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontFamily: 'Poppins',
                  fontSize: 13),
            ),
            subtitle: Row(
              children: [
                // الكونتينر الذي يحتوي على القلب وكلمة "Safe"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white, // اللون ثابت أبيض للـ Container
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: isActive
                            ? Colors.green
                            : Colors.grey, // تغير اللون عند النشاط
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(
                            color: isActive ? Colors.green : Colors.grey,
                            fontFamily: 'Poppins' // تغير اللون عند النشاط
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: onRemove != null
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isActive ? Colors.white : Colors.black54,
                      size: 20,
                    ),
                    onPressed: onRemove,
                  )
                : null,
          ),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return MapScreen();
              }));
            },
            child: Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/map.jpg',
                  fit: BoxFit.cover,
                )),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color: isActive ? Colors.white : Colors.black54),
              const SizedBox(width: 10),
              Text(
                date,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.black54,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.access_time,
                  color: isActive ? Colors.white : Colors.black54),
              const SizedBox(width: 10),
              Text(
                time,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.black54,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.location_on,
                  color: isActive ? Colors.white : Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                      color: isActive ? Colors.white : Colors.black54,
                      fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LocationMapCard extends StatelessWidget {
  final LocationNotificationModel locationModel;
  const LocationMapCard({Key? key, required this.locationModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.person_pin_circle),
            title: Text(locationModel.travelerName),
            subtitle: Text('Trip ID: ${locationModel.tripId}'),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter:
                    LatLng(locationModel.latitude, locationModel.longitude),
                initialZoom: 15,
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
                      point: LatLng(
                          locationModel.latitude, locationModel.longitude),
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
              'Latitude: ${locationModel.latitude}, Longitude: ${locationModel.longitude}'),
          Text('Timestamp: ${locationModel.timestamp}'),
        ],
      ),
    );
  }
}
