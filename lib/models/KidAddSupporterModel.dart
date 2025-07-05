class KidAddSupporterModel {
  final String message;
  final bool success;
  final String? supporterId;
  final String? supporterName;
  final String? kidId;
  final String? kidName;

  KidAddSupporterModel({
    required this.message,
    this.success = false,
    this.supporterId,
    this.supporterName,
    this.kidId,
    this.kidName,
  });

  factory KidAddSupporterModel.fromJson(Map<String, dynamic> json) {
    return KidAddSupporterModel(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      supporterId: json['supporterId'],
      supporterName: json['supporterName'] ?? json['name'],
      kidId: json['kidId'] ?? json['travelerId'],
      kidName: json['kidName'] ?? json['travelerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
      'supporterId': supporterId,
      'supporterName': supporterName,
      'kidId': kidId,
      'kidName': kidName,
    };
  }
}
