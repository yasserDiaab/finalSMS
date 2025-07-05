import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/models/updatelocationModel.dart';

import '../core/API/dio_consumer.dart';

class UpdateLocationRepository {
  final DioConsumer api;

  UpdateLocationRepository({required this.api});

  Future<UpdateLocationResponseModel> updateLocation({
    required String tripId,
    required String latitude,
    required String longitude,
  }) async {
    final data = {
      'TripId': tripId,
      'Latitude': latitude,
      'Longitude': longitude,
    };
    final response = await api.post(EndPoint.updateLocation, data: data);
    return UpdateLocationResponseModel.fromJson(response);
  }
}
