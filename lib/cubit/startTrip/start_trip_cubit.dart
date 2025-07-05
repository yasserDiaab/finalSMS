import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/startTrip/start_trip.state.dart';
import 'package:pro/repo/start_trip_repo.dart';

class StartTripCubit extends Cubit<StartTripState> {
  final StartTripRepository repository;

  StartTripCubit(this.repository) : super(StartTripInitial());

  Future<void> startTrip() async {
    emit(StartTripLoading());
    try {
      final result = await repository.startTrip();
      emit(StartTripSuccess(result));
    } catch (e) {
      emit(StartTripError(e.toString()));
    }
  }
}
