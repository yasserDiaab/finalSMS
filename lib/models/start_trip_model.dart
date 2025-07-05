class StartTripResponseModel {
  final bool success;
  final String tripId;
  final bool isNew;
  final String message;
  final String timestamp;

  StartTripResponseModel({
    required this.success,
    required this.tripId,
    required this.isNew,
    required this.message,
    required this.timestamp,
  });

  factory StartTripResponseModel.fromJson(Map<String, dynamic> json) {
    return StartTripResponseModel(
      success: json['success'],
      tripId: json['tripId'],
      isNew: json['isNew'],
      message: json['message'],
      timestamp: json['timestamp'],
    );
  }
}
