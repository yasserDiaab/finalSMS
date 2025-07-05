import 'package:pro/models/trip_location_model.dart';

abstract class TripLocationState {}

class TripLocationInitial extends TripLocationState {}

class TripLocationLoading extends TripLocationState {}

class TripLocationLoaded extends TripLocationState {
  final List<TripLocationModel> locations;

  TripLocationLoaded(this.locations);
}

class TripLocationError extends TripLocationState {
  final String message;

  TripLocationError(this.message);
}
