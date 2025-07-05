import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/cubit/resetpassCubit/reset_password_cubit.dart';
import 'package:pro/login/login.dart';
import 'package:pro/repo/reset_password_repo.dart';
import 'package:pro/widgets/custom_password_field.dart';
import 'package:pro/widgets/login_button.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key, required this.userId}) : super(key: key);
  final String userId;
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResetPasswordCubit(getIt<ResetPasswordRepository>()),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          body: BlocListener<ResetPasswordCubit, ResetPasswordState>(
            listener: (context, state) {
              if (state is ResetPasswordLoading) {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
              } else if (state is ResetPasswordSuccess) {
                Navigator.pop(context); // Dismiss loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FollowSafeAuthScreen()),
                );
              } else if (state is ResetPasswordError) {
                Navigator.pop(context); // Dismiss loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
              }
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 50),
                const Center(
                  child: Text(
                    "Follow Safe",
                    style: TextStyle(
                      color: Color(0xff193869),
                      fontFamily: 'Poppins',
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Center(
                  child: Text(
                    "Reset Your Password",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 21,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Center(
                  child: Text(
                    "The password must be different than before",
                    style: TextStyle(fontSize: 11, fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(height: 40),
                CustomPasswordField(
                  controller: newPasswordController,
                  hintText: "Enter New Password",
                  icon: Icons.lock,
                  isPasswordVisible: isPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 30),
                CustomPasswordField(
                  controller: confirmPasswordController,
                  hintText: "Confirm Password",
                  icon: Icons.lock,
                  isPasswordVisible: isConfirmPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 300),
                LoginButton(
                  onPressed: () {
                    final cubit = context.read<ResetPasswordCubit>();
                    cubit.resetPassword(
                      userId: widget.userId, // Replace with actual user ID
                      newPassword: newPasswordController.text,
                      confirmPassword: confirmPasswordController.text,
                    );
                  },
                  label: 'Continue',
                  Color1: const Color(0xff193869),
                  color2: Colors.white,
                  color3: const Color(0xff193869),
                ),
                const SizedBox(height: 30),
                LoginButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  label: 'Cancel',
                  Color1: Colors.white,
                  color2: Colors.black,
                  color3: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
