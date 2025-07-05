import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/adult-type-cubit/adult_type_cubit.dart';
import 'package:pro/cubit/user_cubit.dart';
import 'package:pro/cubit/user_state.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/home/adult/mode_selector.dart';

import 'package:pro/login/forgot.dart';
import 'package:pro/login/sign_in_listener.dart';
import 'package:pro/login/sign_up_bloc_listener.dart';
import 'package:pro/widgets/account_type_selector.dart';
import 'package:pro/widgets/custom_password_field.dart';
import 'package:pro/widgets/custom_text_field.dart';
import 'package:pro/widgets/header_section.dart';
import 'package:pro/widgets/login_button.dart';
import 'package:pro/widgets/social_login_button.dart';
import 'package:pro/widgets/terms_checkbox.dart';

class FollowSafeAuthScreen extends StatefulWidget {
  @override
  _FollowSafeAuthScreenState createState() => _FollowSafeAuthScreenState();
}

class _FollowSafeAuthScreenState extends State<FollowSafeAuthScreen> {
  final PageController _pageController = PageController();
  bool isLogin = true;
  bool isKidSelected = true;
  bool isChecked = false;
  bool isPasswordVisible = false;
  bool isSignUpPasswordVisible = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void toggleLoginSignUp() {
    setState(() {
      isLogin = !isLogin;
      _pageController.animateToPage(
        isLogin ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          print("✅ Sign Up Success! Navigating...");
          // Navigation is handled in SignUpListener
        } else if (state is SignInSuccess) {
          // Navigation is handled in SignInListener
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              HeaderSection(isLogin: isLogin, onToggle: toggleLoginSignUp),
              Expanded(
                child: Container(
                  color: const Color(0xFFEBEEEF),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      buildLoginPage(),
                      buildSignUpPage(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildLoginPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: ListView(
        children: [
          const SizedBox(height: 10),
          SocialLoginButton(
              icon: Icons.apple, label: "Login with Apple", onPressed: () {}),
          const SizedBox(height: 30),
          SocialLoginButton(
              icon: Icons.g_mobiledata,
              label: "Login with Google",
              onPressed: () {}),
          const SizedBox(height: 40),
          const Center(
              child: Text("or continue with email",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12))),
          const SizedBox(height: 40),
          CustomTextField(
              controller: context.read<UserCubit>().signInEmail,
              hintText: 'Enter your email',
              icon: Icons.email),
          const SizedBox(height: 30),
          CustomPasswordField(
            controller: context.read<UserCubit>().signInPassword,
            hintText: 'Enter your password',
            icon: Icons.lock,
            isPasswordVisible: isPasswordVisible,
            onToggleVisibility: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => ForgotPassword())),
            child: const Text("Forgot Password?",
                style: TextStyle(
                    color: Colors.black, fontFamily: 'Poppins', fontSize: 11)),
          ),
          const SizedBox(height: 40),
          LoginButton(
            onPressed: () {
              Future.microtask(() => context.read<UserCubit>().signIn());
            },
            label: 'Login',
            Color1: const Color(0xff193869),
            color2: Colors.white,
            color3: const Color(0xff193869),
          ),
          const SignInListener(),
        ],
      ),
    );
  }

  Widget buildSignUpPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Form(
        key: context.read<UserCubit>().signUpFormKey,
        child: ListView(
          children: [
            const Text("choose account type :",
                style: TextStyle(
                    color: Color(0xFF193869),
                    fontSize: 18,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 30),
            AccountTypeSelector(
              isKidSelected: isKidSelected,
              onSelected: (isKid) => setState(() {
                isKidSelected = isKid;
                context.read<UserCubit>().userType.text =
                    isKid ? "kid" : "adult";
                log(context.read<UserCubit>().userType.text);
              }),
            ),
            const SizedBox(height: 43),
            CustomTextField(
                hintText: 'Enter your name',
                icon: Icons.person,
                controller: context.read<UserCubit>().signUpName),
            const SizedBox(height: 30),
            CustomTextField(
                controller: context.read<UserCubit>().signUpEmail,
                hintText: 'Enter your email',
                icon: Icons.email),
            const SizedBox(height: 30),
            CustomTextField(
                controller: context.read<UserCubit>().signUpPhoneNumber,
                hintText: 'Enter your phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 30),
            CustomPasswordField(
              controller: context.read<UserCubit>().signUpPassword,
              hintText: 'Enter your password',
              icon: Icons.lock,
              isPasswordVisible: isSignUpPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  isSignUpPasswordVisible = !isSignUpPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 20),
            TermsCheckbox(
                isChecked: isChecked,
                onChanged: (value) => setState(() => isChecked = value!)),
            const SizedBox(height: 20),
            LoginButton(
              onPressed: () => context.read<UserCubit>().signUp(),
              label: 'Sign Up',
              Color1: const Color(0xff193869),
              color2: Colors.white,
              color3: const Color(0xff193869),
            ),
            const SizedBox(height: 10),
            const SignUpListener(),
          ],
        ),
      ),
    );
  }
}
