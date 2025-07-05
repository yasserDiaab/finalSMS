class EndTripResponseModel {
  final bool success;
  final String message;
  final String timestamp;

  EndTripResponseModel({
    required this.success,
    required this.message,
    required this.timestamp,
  });

  factory EndTripResponseModel.fromJson(Map<String, dynamic> json) {
    return EndTripResponseModel(
      success: json['success'],
      message: json['message'],
      timestamp: json['timestamp'],
    );
  }
}
