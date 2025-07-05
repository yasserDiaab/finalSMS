import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/models/end_trip_model.dart';

import '../core/API/dio_consumer.dart';

class EndTripRepository {
  final DioConsumer api;

  EndTripRepository({required this.api});

  Future<EndTripResponseModel> endTrip({
    required String tripId,
  }) async {
    final data = {
      'TripId': tripId,
    };
    final response = await api.post(EndPoint.endTrip, data: data);
    return EndTripResponseModel.fromJson(response);
  }
}
