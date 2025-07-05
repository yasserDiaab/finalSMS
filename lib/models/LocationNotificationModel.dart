class LocationNotificationModel {
  final String tripId;
  final String travelerId;
  final String travelerName;
  final double latitude;
  final double longitude;
  final String timestamp;

  LocationNotificationModel({
    required this.tripId,
    required this.travelerId,
    required this.travelerName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationNotificationModel.fromJson(Map<String, dynamic> json) {
    return LocationNotificationModel(
      tripId: json['TripId'] ?? json['tripId'] ?? '',
      travelerId: json['TravelerId'] ?? json['travelerId'] ?? '',
      travelerName: json['TravelerName'] ?? json['travelerName'] ?? '',
      latitude: (json['Latitude'] ?? json['latitude'] ?? 0).toDouble(),
      longitude: (json['Longitude'] ?? json['longitude'] ?? 0).toDouble(),
      timestamp: json['Timestamp'] ?? json['timestamp'] ?? '',
    );
  }
} 