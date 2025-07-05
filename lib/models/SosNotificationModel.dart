class SosNotificationModel {
  final double latitude;
  final double longitude;
  final String message;
  final String travelerId;
  final String travelerName;
  final DateTime timestamp;
  final String? userType; // NEW: Traveler / Kid / etc.
  final List<String>?
      supporterIds; // supporters who should receive this notification

  SosNotificationModel({
    required this.latitude,
    required this.longitude,
    required this.message,
    required this.travelerId,
    required this.travelerName,
    required this.timestamp,
    this.userType,
    this.supporterIds,
  });

  factory SosNotificationModel.fromJson(Map<String, dynamic> json) {
    print('SOS JSON: $json');
    double latitude = 0.0;
    double longitude = 0.0;

    // حاول استخراج الإحداثيات من json مباشرة
    if (json.containsKey('latitude')) {
      latitude = double.tryParse(json['latitude'].toString()) ?? 0.0;
    }
    if (json.containsKey('longitude')) {
      longitude = double.tryParse(json['longitude'].toString()) ?? 0.0;
    }

    // إذا لم تكن موجودة كحقول، استخرجها من نص الرسالة
    if (latitude == 0.0 || longitude == 0.0) {
      final msg = json['message']?.toString() ?? '';
      final latMatch = RegExp(r'Latitude\s*=\s*([0-9.]+)').firstMatch(msg);
      final lngMatch = RegExp(r'Longitude\s*=\s*([0-9.]+)').firstMatch(msg);
      if (latMatch != null) {
        latitude = double.tryParse(latMatch.group(1)!) ?? 0.0;
      }
      if (lngMatch != null) {
        longitude = double.tryParse(lngMatch.group(1)!) ?? 0.0;
      }
    }

    final supporterIds = json['supporterIds'] != null
        ? List<String>.from(json['supporterIds'])
        : null;

    return SosNotificationModel(
      latitude: latitude,
      longitude: longitude,
      message: json['message'] ?? 'SOS Alert!',
      travelerId: json['travelerId'] ?? '',
      travelerName: json['travelerName'] ?? 'Unknown Traveler',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      userType: json['userType'], // parse userType from payload
      supporterIds: supporterIds,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'latitude': latitude,
      'longitude': longitude,
      'message': message,
      'travelerId': travelerId,
      'travelerName': travelerName,
      'timestamp': timestamp.toIso8601String(),
      'userType': userType,
      'sendToSupportersOnly': true, // always send only to supporters
    };

    if (supporterIds != null) {
      data['supporterIds'] = supporterIds;
    }

    return data;
  }
}

class SosResponse {
  final bool success;
  final String message;
  final String? messageId;
  final int? recipientCount;
  final String? userType; // Traveler / Kid / etc.
  final List<String>? supporterIds;

  SosResponse({
    required this.success,
    required this.message,
    this.messageId,
    this.recipientCount,
    this.userType,
    this.supporterIds,
  });

  factory SosResponse.fromJson(Map<String, dynamic> json) {
    return SosResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown response',
      messageId: json['messageId']?.toString(),
      recipientCount: json['recipientCount'] is int
          ? json['recipientCount']
          : int.tryParse(json['recipientCount']?.toString() ?? ''),
      userType: json['userType']?.toString(),
      supporterIds: json['supporterIds'] != null
          ? List<String>.from(
              (json['supporterIds'] as List).map((id) => id.toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'success': success,
      'message': message,
      'messageId': messageId,
      'recipientCount': recipientCount,
      'userType': userType,
    };

    if (supporterIds != null) {
      data['supporterIds'] = supporterIds;
    }

    return data;
  }
}
