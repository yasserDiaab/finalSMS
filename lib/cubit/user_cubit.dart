import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/cubit/user_state.dart';
import 'package:pro/models/profileModel.dart';
import 'package:pro/models/SignInModel.dart';
import 'package:pro/repo/UserRepository.dart';
import 'package:http/http.dart' as http;

class UserCubit extends Cubit<UserState> {
  UserCubit(this.userRepository) : super(UserInitial());
  final UserRepository userRepository;

  // Form Keys
  GlobalKey<FormState> signInFormKey = GlobalKey();
  GlobalKey<FormState> signUpFormKey = GlobalKey();

  // Controllers
  TextEditingController signInEmail = TextEditingController();
  TextEditingController signInPassword = TextEditingController();
  TextEditingController signUpName = TextEditingController();
  TextEditingController signUpPhoneNumber = TextEditingController();
  TextEditingController signUpEmail = TextEditingController();
  TextEditingController signUpPassword = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController userType = TextEditingController();
  TextEditingController otpCode = TextEditingController();

  // Profile Pic
  XFile? profilePic;

  // User Model
  SignInModel? user;
  ProfileModel? profileModel;

  // ✅ Upload Profile Pic
  void uploadProfilePic(XFile image) {
    profilePic = image;
    emit(UploadProfilePic());
  }

  // ✅ Sign Up
  Future<void> signUp() async {
    emit(SignUpLoading());
    final response = await userRepository.signUp(
      name: signUpName.text,
      email: signUpEmail.text,
      password: signUpPassword.text,
      userType: userType.text,
      phoneNumber: signUpPhoneNumber.text, // إضافة رقم الهاتف
    );

    response.fold(
      (errMessage) => emit(SignUpFailure(errMessage: errMessage)),
      (signUpModel) => emit(SignUpSuccess(
          message: 'Sign-up successful 🎉', signUpModel: signUpModel)),
    );
  }

  // ✅ Sign In
  Future<void> signIn() async {
    emit(SignInLoading());
    final response = await userRepository.signIn(
      email: signInEmail.text,
      password: signInPassword.text,
    );
    response.fold(
      (errMessage) => emit(SignInFailure(errMessage: errMessage)),
      (signInModel) async {
        user = signInModel;

        // 🧠 تأكد إن عندك بيانات token و userId في signInModel
        final token = signInModel.token;
        final userId = signInModel.userId;

        if (token != null && token.isNotEmpty) {
          await CacheHelper.saveData(key: 'token', value: token);
          log("✅ Token saved to cache: $token");
        } else {
          log("⚠️ Token is null or empty");
        }

        if (userId != null && userId.isNotEmpty) {
          await CacheHelper.saveData(key: 'userId', value: userId);
          log("✅ User ID saved to cache: $userId");
        } else {
          log("⚠️ User ID is null or empty");
        }

        emit(SignInSuccess(userModel: signInModel));
      },
    );
  }
  //Get Profile

  Future<void> getProfile() async {
    emit(GetProfileLoading());

    final token = CacheHelper.getData(key: 'token');

    if (token == null) {
      emit(GetProfileFailure("لا يوجد توكن محفوظ"));
      return;
    }

    try {
      final response = await Dio().get(
        'https://followsafe.runasp.net/Supporter/GetProfile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;
      print('📥 GET PROFILE DATA: $data');
      final profile = ProfileModel.fromJson(data);
      this.profileModel = profile;
      emit(GetProfileSuccess(profileModel: profile));
    } catch (e) {
      emit(GetProfileFailure("فشل في جلب البيانات: ${e.toString()}"));
    }
  }

  //update profile
  Future<void> updateProfile({
    required String fullName,
    required String userName,
    required String phoneNumber,
    required String email,
    required String dateOfBirth, // لازم يكون "YYYY-MM-DD"
  }) async {
    emit(UpdateProfileLoading());

    final token = CacheHelper.getData(key: 'token');

    if (token == null || token.isEmpty) {
      emit(UpdateProfileFailure("Missing authentication token"));
      return;
    }

    print('🔑 Token used in request: $token');

    try {
      final response = await http.put(
          Uri.parse('https://followsafe.runasp.net/Supporter/UpdateProfile'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "fullName": fullName,
            "phoneNumber": phoneNumber,
            "email": email,
            "dateOfBirth": dateOfBirth, // يجب أن يكون بصيغة "yyyy-MM-dd"
          }));
      print(fullName);
      print(phoneNumber);
      print(email);
      print(dateOfBirth);
      print('🔁 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 204) {
        print("fulname$fullName");
        print(phoneNumber);
        print(email);
        print(dateOfBirth);
        await getProfile();
        // إنشاء نسخة جديدة من ProfileModel بالقيم المرسلة
        profileModel = ProfileModel(
          fullName: fullName,
          userName: userName,
          phoneNumber: phoneNumber,
          email: email,
          dateOfBirth: dateOfBirth,
        );

        // بث الحالة مع البيانات الجديدة
        emit(UpdateProfileSuccess(profileModel!));
      } else {
        String errorMessage = 'Update failed';
        try {
          final error = jsonDecode(response.body);
          if (error['errors'] != null) {
            errorMessage = error['errors'].toString();
          } else {
            errorMessage = error['message'] ?? errorMessage;
          }
        } catch (_) {}
        emit(UpdateProfileFailure(errorMessage));
      }
    } catch (e) {
      emit(UpdateProfileFailure("Exception: $e"));
    }
  }

  // ✅ Save Default Mode
  Future<void> saveDefaultMode(String mode) async {
    // Save to general default mode
    await CacheHelper.saveDefaultMode(mode);

    // Also save user-specific preference if user is logged in
    if (user != null && user!.userId.isNotEmpty) {
      final userModeKey = "user_mode_${user!.userId}";
      await CacheHelper.saveData(key: userModeKey, value: mode);
      log("User-specific mode saved successfully for user: ${user!.userId}");
    } else {
      log("WARNING: Cannot save user-specific mode - user ID is invalid");
    }

    emit(UserModeChanged(userMode: mode));
  }

  void clearControllers() {
    signInEmail.clear();
    signInPassword.clear();
    signUpName.clear();
    signUpPhoneNumber.clear();
    signUpEmail.clear();

    signUpPassword.clear();
    confirmPassword.clear();
    userType.clear();
    otpCode.clear();
  }
}
