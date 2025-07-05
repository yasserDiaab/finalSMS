import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/updateLocation/updateLocation_state.dart';

import 'package:pro/repo/update_location_repo.dart';

class UpdateLocationCubit extends Cubit<UpdateLocationState> {
  final UpdateLocationRepository repository;

  UpdateLocationCubit(this.repository) : super(UpdateLocationInitial());

  Future<void> updateLocation({
    required String tripId,
    required String latitude,
    required String longitude,
  }) async {
    emit(UpdateLocationLoading());
    try {
      final result = await repository.updateLocation(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
      );
      emit(UpdateLocationSuccess(result));
    } catch (e) {
      emit(UpdateLocationError(e.toString()));
    }
  }
}
