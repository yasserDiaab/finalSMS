import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/home/adult/edit_profile_page.dart';
import '../../cache/CacheHelper.dart';
import '../../cubit/user_cubit.dart';
import '../../cubit/user_state.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final token = CacheHelper.getData(key: 'token');
    if (token != null) {
      context.read<UserCubit>().getProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const EditProfileScreen();
                }));
              },
            ),
          ],
        ),
        body: BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            if (state is GetProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // سواء نجح أو فشل، بنجهز بيانات العرض
            String fullName = 'Test';
            String userName = '';
            String phone = '';
            String email = 'Test@gmail.com';
            String dob = '';

            if (state is GetProfileSuccess) {
              final model = state.profileModel;
              fullName = model.fullName ?? '';
              userName = model.userName ?? '';
              phone = model.phoneNumber ?? '';
              email = model.email ?? '';
              dob = model.dateOfBirth ?? '';
            }

            // تعبئة الكنترولات
            fullNameController.text = fullName;
            userNameController.text = userName;
            phoneController.text = phone;
            emailController.text = email;
            dobController.text = dob;

            return Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(height: 70, color: Colors.white),
                    const Positioned(
                      top: 20,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/man.jpeg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
                Text(
                  email,
                  style: const TextStyle(
                      color: Colors.grey, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      buildProfileItem(
                          Icons.person, 'Full Name', fullNameController),
                      buildProfileItem(Icons.account_circle, 'User Name',
                          userNameController),
                      buildProfileItem(
                          Icons.phone, 'Phone number', phoneController),
                      buildProfileItem(
                          Icons.email, 'Email Address', emailController),
                      buildProfileItem(
                          Icons.calendar_today, 'Date of Birth', dobController),
                      const Divider(
                          color: Colors.black, thickness: 1.5, height: 32),
                      buildActionItem(Icons.delete, 'Clear data', () {
                        CacheHelper.clearData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Data cleared")),
                        );
                      }),
                      const SizedBox(height: 4),
                      buildActionItem(Icons.logout, 'Log out', () {
                        CacheHelper.clearData();
                        Navigator.of(context).pushReplacementNamed('/login');
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ));
  }

  Widget buildProfileItem(
      IconData icon, String title, TextEditingController controller) {
    bool hasValue = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: hasValue
                  ? Text(
                      controller.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    )
                  : TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: title,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionItem(IconData icon, String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
