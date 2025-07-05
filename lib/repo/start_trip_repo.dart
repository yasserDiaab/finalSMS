import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/models/start_trip_model.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'dart:developer';

import '../core/API/dio_consumer.dart';

class StartTripRepository {
  final DioConsumer api;

  StartTripRepository({required this.api});

  Future<StartTripResponseModel> startTrip() async {
    try {
      log("🚗 StartTripRepository: Starting trip...");
      
      // Get traveler ID from cache
      final travelerId = CacheHelper.getData(key: ApiKey.userId)?.toString();
      if (travelerId == null || travelerId.isEmpty) {
        throw Exception("Traveler ID not found. Please log in again.");
      }
      
      // Get traveler name from cache or token
      final travelerName = CacheHelper.getData(key: ApiKey.name)?.toString() ?? 
                          CacheHelper.getData(key: "userName")?.toString() ??
                          CacheHelper.getData(key: "fullName")?.toString() ??
                          "Unknown Traveler";
      
      // Include traveler ID and name in request body
      final data = {
        'TravelerId': travelerId,
        'TravelerName': travelerName,
      };
      
      log("🚗 StartTripRepository: Sending request with data:");
      log("  - TravelerId: $travelerId");
      log("  - TravelerName: $travelerName");
      log("  - Full request data: $data");
      log("  - Endpoint: ${EndPoint.startTrip}");
      
      final response = await api.post(EndPoint.startTrip, data: data);
      
      log("🚗 StartTripRepository: Raw response: $response");
      log("🚗 StartTripRepository: Response type: ${response.runtimeType}");
      
      if (response is Map<String, dynamic>) {
        log("🚗 StartTripRepository: Response keys: ${response.keys.toList()}");
        log("🚗 StartTripRepository: Success: ${response['success']}");
        log("🚗 StartTripRepository: TripId: ${response['tripId']}");
        log("🚗 StartTripRepository: Message: ${response['message']}");
      }
      
      log("🚗 StartTripRepository: Trip started successfully");
      return StartTripResponseModel.fromJson(response);
    } catch (e) {
      log("❌ StartTripRepository: Error starting trip: $e");
      
      // Check if it's a SignalR connection error
      if (e.toString().contains("TRAVELER_DISCONNECTED") || 
          e.toString().contains("must be connected")) {
        log("⚠️ StartTripRepository: SignalR connection issue detected");
        log("💡 Tip: The server requires SignalR connection before starting a trip");
        log("💡 The connection is established, but the server might need more time");
        throw Exception("SignalR connection required. Please try again in a few seconds.");
      }
      
      throw Exception("Failed to start trip: $e");
    }
  }
}
