import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/cubit/forgetCubit/forget_password_cubit.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/login/otp2.dart';
import 'package:pro/models/forget_password_model.dart';
import 'package:pro/models/forget_password_model.dart';
import 'package:pro/repo/forgetrepo.dart';
import 'package:pro/widgets/custom_text_field.dart';
import 'package:pro/widgets/login_button.dart';

class ForgotPassword extends StatelessWidget {
  ForgotPassword({super.key});

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgetPasswordCubit(getIt<ForgetRepo>()), // Use GetIt here
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocListener<ForgetPasswordCubit, ForgetPasswordState>(
          listener: (context, state) {
            if (state is ForgetPasswordSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("OTP has been sent successfully!"),
                    backgroundColor: Colors.green),
              );
              final userId = state.forgetPasswordModel.userId;
              log("========================================userId:$userId!");
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OTP2(
                          id: userId,
                        )),
              );
            } else if (state is ForgetPasswordFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.errMessage),
                    backgroundColor: Colors.red),
              );
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "Follow Safe",
                  style: TextStyle(
                      color: Color(0xff193869),
                      fontFamily: 'Poppins',
                      fontSize: 20),
                ),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "Forget Password",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 19),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "Enter your email account to reset password",
                  style: TextStyle(color: Colors.grey[700], fontSize: 11),
                ),
              ),
              const SizedBox(height: 30),
              Image.asset("assets/images/img7.png", height: 330),
              const SizedBox(height: 30),
              CustomTextField(
                hintText: "Enter your email",
                icon: Icons.email,
                controller: emailController,
              ),
              const SizedBox(height: 30),
              BlocBuilder<ForgetPasswordCubit, ForgetPasswordState>(
                builder: (context, state) {
                  return LoginButton(
                    onPressed: () {
                      final email = emailController.text.trim();
                      if (email.isNotEmpty) {
                        context
                            .read<ForgetPasswordCubit>()
                            .forgetPassword(email);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter your email"),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    label: state is ForgetPasswordLoading
                        ? 'Sending...'
                        : 'Continue',
                    Color1: const Color(0xff193869),
                    color2: Colors.white,
                    color3: const Color(0xff193869),
                  );
                },
              ),
              const SizedBox(height: 30),
              LoginButton(
                onPressed: () => Navigator.pop(context),
                label: 'Cancel',
                Color1: Colors.white,
                color2: Colors.black,
                color3: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
