class SupporterPhoneModel {
  final int? id;
  final String supporterId;
  final String supporterName;
  final String phoneNumber;
  final String? email;
  final DateTime lastUpdated;
  final bool isActive;

  SupporterPhoneModel({
    this.id,
    required this.supporterId,
    required this.supporterName,
    required this.phoneNumber,
    this.email,
    required this.lastUpdated,
    this.isActive = true,
  });

  factory SupporterPhoneModel.fromJson(Map<String, dynamic> json) {
    try {
      return SupporterPhoneModel(
        supporterId:
            json['supporterId']?.toString() ?? json['id']?.toString() ?? '',
        supporterName:
            json['supporterName']?.toString() ?? json['name']?.toString() ?? '',
        phoneNumber:
            json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
        email: json['email']?.toString(),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'].toString()) ??
                DateTime.now()
            : DateTime.now(),
        isActive: json['isActive'] == true || json['isActive'] == 1,
      );
    } catch (e) {
      print('❌ Error parsing SupporterPhoneModel from JSON: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supporterId': supporterId,
      'supporterName': supporterName,
      'phoneNumber': phoneNumber,
      'email': email,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supporterId': supporterId,
      'supporterName': supporterName,
      'phoneNumber': phoneNumber,
      'email': email,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory SupporterPhoneModel.fromMap(Map<String, dynamic> map) {
    return SupporterPhoneModel(
      id: map['id'],
      supporterId: map['supporterId'],
      supporterName: map['supporterName'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      isActive: map['isActive'] == 1,
    );
  }

  SupporterPhoneModel copyWith({
    int? id,
    String? supporterId,
    String? supporterName,
    String? phoneNumber,
    String? email,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return SupporterPhoneModel(
      id: id ?? this.id,
      supporterId: supporterId ?? this.supporterId,
      supporterName: supporterName ?? this.supporterName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }
}
