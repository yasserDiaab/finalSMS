import 'package:pro/models/active_trip_model.dart';
import 'package:pro/models/trip_location_model.dart';
import '../core/API/api_consumer.dart';

class SupporterTrackingRepository {
  final ApiConsumer api;

  SupporterTrackingRepository(this.api);

  Future<List<ActiveTripModel>> getActiveTrips() async {
    final response = await api.get('SupporterTracking/active-trips');
    return (response as List).map((e) => ActiveTripModel.fromJson(e)).toList();
  }

  Future<List<TripLocationModel>> getTripLocations(String tripId) async {
    final response = await api.get('SupporterTracking/trip-locations/$tripId');
    return (response as List)
        .map((e) => TripLocationModel.fromJson(e))
        .toList();
  }
}
