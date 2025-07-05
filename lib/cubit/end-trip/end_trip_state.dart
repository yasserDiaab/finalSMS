import 'package:equatable/equatable.dart';
import 'package:pro/models/end_trip_model.dart';

abstract class EndTripState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EndTripInitial extends EndTripState {}

class EndTripLoading extends EndTripState {}

class EndTripSuccess extends EndTripState {
  final EndTripResponseModel response;

  EndTripSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class EndTripError extends EndTripState {
  final String message;

  EndTripError(this.message);

  @override
  List<Object?> get props => [message];
}
