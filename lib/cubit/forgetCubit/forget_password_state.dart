part of 'forget_password_cubit.dart';

abstract class ForgetPasswordState extends Equatable {
  const ForgetPasswordState();

  @override
  List<Object> get props => [];
}

class ForgetPasswordInitial extends ForgetPasswordState {}

class ForgetPasswordLoading extends ForgetPasswordState {}

class ForgetPasswordSuccess extends ForgetPasswordState {
  final String message;
  final ForgetPasswordModel forgetPasswordModel;

  const ForgetPasswordSuccess(
      {required this.message, required this.forgetPasswordModel});
}

class ForgetPasswordFailure extends ForgetPasswordState {
  final String errMessage;
  const ForgetPasswordFailure({required this.errMessage});
}
