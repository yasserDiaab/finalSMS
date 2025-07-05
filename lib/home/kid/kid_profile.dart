import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/kid_profile/kid_profile_cubit.dart';
import 'package:pro/cubit/kid_profile/kid_profile_state.dart';
import 'package:pro/home/kid/trusted_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cache/CacheHelper.dart';

class KidProfileScreen extends StatefulWidget {
  @override
  _KidProfileScreenState createState() => _KidProfileScreenState();
}

class _KidProfileScreenState extends State<KidProfileScreen> {
  bool showDialogBox = false;
  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  void fetchProfile() async {
    final token = CacheHelper.getData(key: 'token');
    if (token != null && context.mounted) {
      context.read<KidProfileCubit>().getProfile(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // جعل الخلفية بيضاء
      body: Container(
        width: screenWidth, // يملأ العرض بالكامل
        height: screenHeight, // يملأ الارتفاع بالكامل
        decoration: const BoxDecoration(
          color: Colors.white, // لون الخلفية
        ),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 165),
              height: screenHeight, // يملأ الارتفاع بالكامل
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3BE489), Color(0xFF00C2E0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 60, // زيادة القيمة من 40 إلى 60
              left: 20,
              right: 20,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back_ios, size: 18),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "My Profile",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 120, // زيادة القيمة من 100 إلى 120
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/girl.png",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 240, // زيادة القيمة من 220 إلى 240
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              child: BlocBuilder<KidProfileCubit, KidProfileState>(
                builder: (context, state) {
                  if (state is KidProfileLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is KidProfileLoaded) {
                    final profile = state.profile;
                    return Column(
                      children: [
                        buildProfileItem(
                            Icons.person, "Name", profile.fullName),
                        buildProfileItem(
                            Icons.email, "Email", profile.userName),
                        buildProfileItem(Icons.calendar_today, "Age",
                            profile.dateOfBirth ?? "Not set"),
                        buildProfileItem(
                            Icons.favorite, "Safety mode status", "Active"),
                        buildProfileItem(
                          Icons.emoji_events,
                          "Achievements",
                          "",
                          onTap: () {
                            setState(() {
                              showDialogBox = true;
                            });
                          },
                        ),
                        buildProfileItem(Icons.group, "Trusted contacts", '',
                            onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return const TrustedContactsScreen();
                          }));
                        }),
                      ],
                    );
                  } else if (state is KidProfileError) {
                    return Center(child: Text("Error: ${state.message}"));
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            if (showDialogBox)
              Positioned(
                top: 270, // زيادة القيمة من 250 إلى 270
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "You have used safety mode 5 times! 🎉",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showDialogBox = false;
                            });
                          },
                          child: const Text(
                            "OK",
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileItem(IconData icon, String title, String value,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 25), // زيادة المسافة من 15 إلى 25
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            if (value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}
