class KidProfileModel {
  final String fullName;
  final String userName;
  final String? dateOfBirth;

  KidProfileModel({
    required this.fullName,
    required this.userName,
    this.dateOfBirth,
  });

  factory KidProfileModel.fromJson(Map<String, dynamic> json) {
    return KidProfileModel(
      fullName: json['fullName'] ?? '',
      userName: json['userName'] ?? '',
      dateOfBirth: json['dateOfBirth'],
    );
  }
}
