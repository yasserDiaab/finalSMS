import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/repo/end_trip_repo.dart';

import 'end_trip_state.dart';

class EndTripCubit extends Cubit<EndTripState> {
  final EndTripRepository repository;
  EndTripCubit(this.repository) : super(EndTripInitial());

  Future<void> endTrip(String tripId) async {
    emit(EndTripLoading());
    try {
      final result = await repository.endTrip(tripId: tripId);
      emit(EndTripSuccess(result));
    } catch (e) {
      emit(EndTripError(e.toString()));
    }
  }
}
