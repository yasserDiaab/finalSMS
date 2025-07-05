part of 'adult_type_cubit.dart';

abstract class AdultTypeState {}

class AdultTypeInitial extends AdultTypeState {}

class AdultTypeLoading extends AdultTypeState {}

class AdultTypeSuccess extends AdultTypeState {
  final String message;
  AdultTypeSuccess(this.message);
}

class AdultTypeError extends AdultTypeState {
  final String error;
  AdultTypeError(this.error);
}
