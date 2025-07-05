import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/activeTrip/active_trip_state.dart';
import 'package:pro/models/active_trip_model.dart';
import 'package:pro/repo/supporter_tracking_repo.dart';

class ActiveTripsCubit extends Cubit<ActiveTripsState> {
  final SupporterTrackingRepository repository;

  ActiveTripsCubit(this.repository) : super(ActiveTripsInitial());

  Future<void> fetchActiveTrips() async {
    emit(ActiveTripsLoading());
    try {
      final trips = await repository.getActiveTrips();
      emit(ActiveTripsLoaded(trips));
    } catch (e) {
      emit(ActiveTripsError(e.toString()));
    }
  }
}
