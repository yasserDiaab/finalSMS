part of 'otp_cubit.dart';

abstract class OtpState extends Equatable {
  const OtpState();

  @override
  List<Object> get props => [];
}

class OtpInitial extends OtpState {}

class OtpLoading extends OtpState {}

class OtpSuccess extends OtpState {}

class OtpError extends OtpState {
  final String error;
  const OtpError({required this.error});
}
