class TravelersListModel {
  final bool success;
  final String message;
  final List<TravelerItem> travelers;
  final List<TravelerItem> kids;

  TravelersListModel({
    required this.success,
    required this.message,
    required this.travelers,
    required this.kids,
  });

  factory TravelersListModel.fromJson(Map<String, dynamic> json) {
    List<TravelerItem> travelersList = [];
    List<TravelerItem> kidsList = [];

    if (json.containsKey('travelers') && json['travelers'] is List) {
      travelersList = List<TravelerItem>.from(
        json['travelers'].map((traveler) => TravelerItem.fromJson(traveler)),
      );
    }

    if (json.containsKey('kids') && json['kids'] is List) {
      kidsList = List<TravelerItem>.from(
        json['kids'].map((kid) => TravelerItem.fromJson(kid)),
      );
    }

    return TravelersListModel(
      success:
          json['success'] ?? (travelersList.isNotEmpty || kidsList.isNotEmpty),
      message: json['message'] ?? '',
      travelers: travelersList,
      kids: kidsList,
    );
  }
}

class TravelerItem {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? supporterId;
  final String? supporterName;

  TravelerItem({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.supporterId,
    this.supporterName,
  });

  factory TravelerItem.fromJson(Map<String, dynamic> json) {
    return TravelerItem(
      id: json['id'] ?? json['travelerId'] ?? '',
      name: json['name'] ?? json['travelerName'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? json['profilePic'],
      supporterId: json['supporterId'],
      supporterName: json['supporterName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'supporterId': supporterId,
      'supporterName': supporterName,
    };
  }
}
