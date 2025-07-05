import 'package:equatable/equatable.dart';
import 'package:pro/models/SignInModel.dart';
import 'package:pro/models/SignUpModel.dart';

import '../models/profileModel.dart';

abstract class UserState extends Equatable {
  @override
  List<Object?> get props => [];

  String? get errMessage => null;
}

class UserInitial extends UserState {}

// ✅ Sign Up States
class SignUpLoading extends UserState {}

class SignUpSuccess extends UserState {
  final String message;
  final SignUpModel signUpModel;

  SignUpSuccess({
    required this.message,
    required this.signUpModel,
  });
}

class SignUpFailure extends UserState {
  final String errMessage;
  SignUpFailure({required this.errMessage});
}

// ✅ Sign In States
class SignInLoading extends UserState {}

class SignInSuccess extends UserState {
  final SignInModel userModel; // ✅  userModel

  SignInSuccess({required this.userModel});

  @override
  List<Object?> get props => [userModel];
}

class SignInFailure extends UserState {
  final String errMessage;
  SignInFailure({required this.errMessage});
}

// ✅ Get User Profile
class GetUserLoading extends UserState {}

class GetUserSuccess extends UserState {
  final SignInModel user;
  GetUserSuccess({required this.user});
}

class GetUserFailure extends UserState {
  final String errMessage;
  GetUserFailure({required this.errMessage});
}

// ✅ Forgot Password
class ForgotPasswordLoading extends UserState {}

class ForgotPasswordSuccess extends UserState {
  final String message;
  ForgotPasswordSuccess({required this.message});
}

class ForgotPasswordFailure extends UserState {
  final String errMessage;
  ForgotPasswordFailure({required this.errMessage});
}

// ✅ Upload Profile Pic
class UploadProfilePic extends UserState {}

// ✅ OTP States
class OtpSending extends UserState {}

class OtpSendSuccess extends UserState {
  final String message;
  OtpSendSuccess({required this.message});
}

class OtpSendFailure extends UserState {
  final String errMessage;
  OtpSendFailure({required this.errMessage});
}

class OtpVerifying extends UserState {}

class OtpVerifySuccess extends UserState {}

class OtpVerifyFailure extends UserState {
  final String errMessage;
  OtpVerifyFailure({required this.errMessage});
}

// ✅ تمت إضافة الحالة الجديدة المطلوبة
class UserSuccess extends UserState {}

// ✅ حالة تغيير وضع المستخدم
class UserModeChanged extends UserState {
  final String userMode;
  UserModeChanged({required this.userMode});

  @override
  List<Object?> get props => [userMode];
}

// ✅ حالة تغيير نوع المستخدم البالغ (adultType)
class UserAdultTypeChanged extends UserState {
  final String adultType;
  UserAdultTypeChanged({required this.adultType});

  @override
  List<Object?> get props => [adultType];
}

//GEt Profile
class GetProfileLoading extends UserState {}

class GetProfileSuccess extends UserState {
  final ProfileModel profileModel;
  GetProfileSuccess({required this.profileModel});
}

class GetProfileFailure extends UserState {
  final String error;
  GetProfileFailure(this.error);
}

// --- تحديث البيانات ---
class UpdateProfileLoading extends UserState {}

class UpdateProfileSuccess extends UserState {
  final ProfileModel profileModel;

  UpdateProfileSuccess(this.profileModel);

  @override
  List<Object?> get props => [profileModel];
}

class UpdateProfileFailure extends UserState {
  final String errMessage;
  UpdateProfileFailure(this.errMessage);
}
