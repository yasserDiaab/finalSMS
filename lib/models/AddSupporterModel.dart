class AddSupporterModel {
  final String message;
  final bool success;
  final String? supporterId;
  final String? supporterName;
  final String? travelerId;
  final String? travelerName;

  AddSupporterModel({
    required this.message,
    this.success = false,
    this.supporterId,
    this.supporterName,
    this.travelerId,
    this.travelerName,
  });

  factory AddSupporterModel.fromJson(Map<String, dynamic> json) {
    return AddSupporterModel(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      supporterId: json['supporterId'],
      supporterName: json['supporterName'] ?? json['name'],
      travelerId: json['travelerId'],
      travelerName: json['travelerName'],
    );
  }
}
