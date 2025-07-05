import 'package:equatable/equatable.dart';
import 'package:pro/models/start_trip_model.dart';

abstract class StartTripState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartTripInitial extends StartTripState {}

class StartTripLoading extends StartTripState {}

class StartTripSuccess extends StartTripState {
  final StartTripResponseModel response;

  StartTripSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class StartTripError extends StartTripState {
  final String message;

  StartTripError(this.message);

  @override
  List<Object?> get props => [message];
}
