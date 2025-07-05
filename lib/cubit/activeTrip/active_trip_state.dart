import 'package:pro/models/active_trip_model.dart';

abstract class ActiveTripsState {}

class ActiveTripsInitial extends ActiveTripsState {}

class ActiveTripsLoading extends ActiveTripsState {}

class ActiveTripsLoaded extends ActiveTripsState {
  final List<ActiveTripModel> trips;

  ActiveTripsLoaded(this.trips);
}

class ActiveTripsError extends ActiveTripsState {
  final String message;

  ActiveTripsError(this.message);
}
