class ProfileModel {
  final String? fullName;
  final String? userName;
  final String? phoneNumber;
  final String? email;
  final String? dateOfBirth;

  ProfileModel({
    this.fullName,
    this.userName,
    this.phoneNumber,
    this.email,
    this.dateOfBirth,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      fullName: json['fullName'],
      userName: json['userName'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      dateOfBirth: json['dateOfBirth'],
    );
  }
}
