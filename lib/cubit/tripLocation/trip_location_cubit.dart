import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/models/trip_location_model.dart';
import 'package:pro/repo/supporter_tracking_repo.dart';

import 'trip_location_state.dart';

class TripLocationCubit extends Cubit<TripLocationState> {
  final SupporterTrackingRepository repository;

  TripLocationCubit(this.repository) : super(TripLocationInitial());

  Future<void> fetchTripLocations(String tripId) async {
    emit(TripLocationLoading());
    try {
      final locations = await repository.getTripLocations(tripId);
      emit(TripLocationLoaded(locations));
    } catch (e) {
      emit(TripLocationError(e.toString()));
    }
  }
}
