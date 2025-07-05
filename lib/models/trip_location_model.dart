class TripLocationModel {
  final String tripId;
  final String travelerId;
  final String travelerName;
  final double latitude;
  final double longitude;
  final String timeStamp;

  TripLocationModel({
    required this.tripId,
    required this.travelerId,
    required this.travelerName,
    required this.latitude,
    required this.longitude,
    required this.timeStamp,
  });

  factory TripLocationModel.fromJson(Map<String, dynamic> json) {
    return TripLocationModel(
      tripId: json['tripId'],
      travelerId: json['travelerId'],
      travelerName: json['travelerName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timeStamp: json['timesStamp'],
    );
  }
}
