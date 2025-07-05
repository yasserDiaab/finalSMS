part of 'reset_password_cubit.dart';

abstract class ResetPasswordState extends Equatable {
  const ResetPasswordState();

  @override
  List<Object> get props => [];
}

class ResetPasswordInitial extends ResetPasswordState {}

class ResetPasswordLoading extends ResetPasswordState {}

class ResetPasswordSuccess extends ResetPasswordState {
  final String message;

  const ResetPasswordSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ResetPasswordError extends ResetPasswordState {
  final String error;

  const ResetPasswordError(this.error);

  @override
  List<Object> get props => [error];
}
