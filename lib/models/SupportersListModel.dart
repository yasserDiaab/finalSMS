class SupportersListModel {
  final bool success;
  final String message;
  final List<SupporterItem> supporters;

  SupportersListModel({
    required this.success,
    required this.message,
    required this.supporters,
  });

  factory SupportersListModel.fromJson(Map<String, dynamic> json) {
    List<SupporterItem> supportersList = [];
    
    if (json.containsKey('supporters') && json['supporters'] is List) {
      supportersList = List<SupporterItem>.from(
        json['supporters'].map((supporter) => SupporterItem.fromJson(supporter))
      );
    }
    
    return SupportersListModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      supporters: supportersList,
    );
  }
}

class SupporterItem {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? travelerId;
  final String? travelerName;

  SupporterItem({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.travelerId,
    this.travelerName,
  });

  factory SupporterItem.fromJson(Map<String, dynamic> json) {
    return SupporterItem(
      id: json['id'] ?? json['supporterId'] ?? '',
      name: json['name'] ?? json['supporterName'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? json['profilePic'],
      travelerId: json['travelerId'],
      travelerName: json['travelerName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'travelerId': travelerId,
      'travelerName': travelerName,
    };
  }
}
