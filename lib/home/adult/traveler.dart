import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/cubit/sos/sos_cubit.dart';
import 'package:pro/cubit/sos/sos_state.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/home/adult/profile_page.dart';
import 'package:pro/home/adult/settings_page_traveler.dart';
import 'package:pro/home/adult/timer_page.dart';
import 'package:pro/home/adult/traveler_supporter_menu_List.dart';
import 'package:pro/home/adult/nearby_places_map.dart';
import 'package:pro/services/notification_service.dart';
import 'package:pro/services/app_timer_service.dart';
import 'package:pro/widgets/custom_bottom_bar.dart';
import 'package:pro/widgets/header_profile.dart';
import 'dart:developer';

class Traveler extends StatefulWidget {
  const Traveler({super.key});

  @override
  State<Traveler> createState() => _TravelerPageState();
}

class _TravelerPageState extends State<Traveler> {
  int currentIndex = 0; // Current active index in BottomNavigationBar

  @override
  void initState() {
    super.initState();
    // Initialize notification service
    final notificationService = getIt<NotificationService>();
    notificationService.initialize();

    // Initialize SignalR connection for traveler
    _initializeTravelerSignalR();

    // Clear old notifications on startup (optional)
    // notificationService.clearAllNotifications();
  }

  // Initialize SignalR connection for traveler
  Future<void> _initializeTravelerSignalR() async {
    try {
      final timerService = getIt<AppTimerService>();
      await timerService.initializeTravelerSignalR();
      log("✅ Traveler SignalR connection initialized");
    } catch (e) {
      log("❌ Error initializing traveler SignalR: $e");
    }
  }

  // Pages to display based on the selected tab
  final List<Widget> pages = [
    const Center(child: Text('')),
    SettingsScreen(),
    TravelersListWidget(),
    const TimerWidget(),
    ProfilePage(),
  ];

  // Show confirmation dialog before sending SOS
  void _showSosConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Send SOS Alert'),
          content: const Text(
            "Are you sure you want to send an SOS alert to all your supporters? They will receive your current location and an emergency notification.",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Send the SOS notification
                context.read<SosCubit>().sendSosNotification(
                      message: "SOS! I need immediate assistance!",
                    );
              },
              child: const Text("Yes, Send SOS",
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> places = [
      {'name': 'Police station', 'image': 'assets/images/police_station.png'},
      {'name': 'Fire station', 'image': 'assets/images/fire_station.jpg'},
      {'name': 'Hospital', 'image': 'assets/images/hospital.jpeg'},
      {'name': 'Petrol station', 'image': 'assets/images/petrol_station.jpeg'},
      {'name': 'Repair Shop', 'image': 'assets/images/repair_shop.jpeg'},
      {'name': 'Airport', 'image': 'assets/images/airport.jpeg'},
    ];

    return BlocProvider(
      create: (context) {
        final sosCubit = getIt<SosCubit>();
        sosCubit.initialize();
        return sosCubit;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevent overlap with keyboard
        body: currentIndex == 0
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 10), // Add padding at the bottom of the page
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const HeaderProfile(
                          showNotifications: true, userType: 'traveler'),
                      const SizedBox(height: 40),
                      const Padding(
                        padding: EdgeInsets.only(right: 150),
                        child: Text(
                          'Send sos message',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xff212429),
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: 330,
                        height: 90,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65C4F), Color(0xFF80332C)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 330,
                            height: 85,
                            child: BlocConsumer<SosCubit, SosState>(
                              listener: (context, state) {
                                if (state is SosSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'SOS notification sent to your supporters'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                } else if (state is SosFailure) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to send SOS: ${state.error}'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                }
                              },
                              builder: (context, state) {
                                final bool isLoading = state is SosLoading;
                                return ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          _showSosConfirmationDialog(context);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'SOS',
                                          style: TextStyle(
                                            fontSize: 35,
                                            color: Color(0xffF9F9F9),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.only(right: 160),
                        child: Text(
                          'Weather updates',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xff212429),
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        width: 340,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/image.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.only(right: 140),
                        child: Text(
                          'Assistants near you',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xff212429),
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 10.0, left: 10),
                              child: GestureDetector(
                                onTap: () {
                                  String selectedPlace = places[index]['name']!;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NearbyPlacesMap(
                                          placeType: selectedPlace),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 120,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffebeeef),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.grey,
                                          image: DecorationImage(
                                            image: AssetImage(
                                                places[index]['image']!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        places[index]['name']!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Poppins'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : pages[
                currentIndex], // Navigate to other pages based on currentIndex
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
    );
  }
}

final List<IconData> bottomBarIcons = [
  Icons.home,
  Icons.settings,
  Icons.menu,
  Icons.timer,
  Icons.person,
];
