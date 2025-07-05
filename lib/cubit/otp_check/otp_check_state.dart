part of 'otp_check_cubit.dart';

abstract class OtpCheckState extends Equatable {
  const OtpCheckState();

  @override
  List<Object> get props => [];
}

class OtpCheckInitial extends OtpCheckState {}

class OtpCheckLoading extends OtpCheckState {}

class OtpCheckSuccess extends OtpCheckState {}

class OtpCheckError extends OtpCheckState {
  final String error;

  const OtpCheckError({required this.error});

  @override
  List<Object> get props => [error];
}
