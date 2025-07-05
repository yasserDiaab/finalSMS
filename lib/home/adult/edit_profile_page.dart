import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/user_cubit.dart';
import 'package:pro/home/adult/profile_page.dart';
import 'package:pro/widgets/login_button.dart';
import '../../cubit/user_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isPasswordVisible = false;

  final fullNameController = TextEditingController();
  final userNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserCubit>().profileModel;
    fullNameController.text = profile?.fullName ?? '';
    userNameController.text = profile?.userName ?? '';
    phoneController.text = profile?.phoneNumber ?? '';
    emailController.text = profile?.email ?? '';
    dobController.text = profile?.dateOfBirth ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UpdateProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else if (state is UpdateProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errMessage)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            toolbarHeight: 90,
            title: const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'Edit Profile',
                style: TextStyle(
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            backgroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          body: Stack(
            children: [
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.grey[100],
                ),
              ),
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/man.jpeg'),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              const Color.fromARGB(255, 62, 147, 226),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // TODO: تنفيذ اختيار صورة جديدة للملف الشخصي
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          buildInputField('Full Name', fullNameController),
                          const SizedBox(height: 15),
                          buildInputField('User name', userNameController),
                          const SizedBox(height: 15),
                          buildInputField('Phone number', phoneController),
                          const SizedBox(height: 15),
                          buildInputField(
                            'Password',
                            passwordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 15),
                          buildInputField('Email address', emailController),
                          const SizedBox(height: 15),
                          buildInputField('Date of Birth', dobController),
                          const SizedBox(height: 30),
                          state is UpdateProfileLoading
                              ? const Center(child: CircularProgressIndicator())
                              : LoginButton(
                                  onPressed: () {
                                    print(
                                        "FULL NAME: ${fullNameController.text}");
                                    print("PHONE: ${phoneController.text}");
                                    print("EMAIL: ${emailController.text}");
                                    print("DOB: ${dobController.text}");
                                    final date = dobController.text.trim();
                                    final dateRegex =
                                        RegExp(r'^\d{4}-\d{2}-\d{2}$');

                                    if (!dateRegex.hasMatch(date)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Please enter date in yyyy-MM-dd format")),
                                      );
                                      return;
                                    }
                                    context.read<UserCubit>().updateProfile(
                                          fullName: fullNameController.text,
                                          phoneNumber: phoneController.text,
                                          userName: userNameController.text,
                                          email: emailController.text,
                                          dateOfBirth: dobController.text,
                                        );
                                  },
                                  label: 'Done',
                                  Color1: const Color(0xff193869),
                                  color2: Colors.white,
                                  color3: const Color(0xff193869),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildInputField(String label, TextEditingController controller,
      {bool isPassword = false, bool isEnabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontFamily: 'Poppins', color: Colors.black),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !_isPasswordVisible : false,
          enabled: isEnabled,
          decoration: InputDecoration(
            hintText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
