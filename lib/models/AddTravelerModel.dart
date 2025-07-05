class AddTravelerModel {
  final String message;
  final bool success;
  final String? travelerId;
  final String? travelerName;
  final String? supporterId;
  final String? supporterName;

  AddTravelerModel({
    required this.message,
    this.success = false,
    this.travelerId,
    this.travelerName,
    this.supporterId,
    this.supporterName,
  });

  factory AddTravelerModel.fromJson(Map<String, dynamic> json) {
    return AddTravelerModel(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      travelerId: json['travelerId'],
      travelerName: json['travelerName'] ?? json['name'],
      supporterId: json['supporterId'],
      supporterName: json['supporterName'],
    );
  }
}
