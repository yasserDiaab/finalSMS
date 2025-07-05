class UpdateLocationResponseModel {
  final bool success;
  final String message;
  final String timestamp;

  UpdateLocationResponseModel({
    required this.success,
    required this.message,
    required this.timestamp,
  });

  factory UpdateLocationResponseModel.fromJson(Map<String, dynamic> json) {
    return UpdateLocationResponseModel(
      success: json['success'],
      message: json['message'],
      timestamp: json['timestamp'],
    );
  }
}
