   class TripNotificationModel {
     final String tripId;
     final String travelerId;
     final String travelerName;
     final String travelerPhone;
     final String startTime;
     final String status;
     final String action;

     TripNotificationModel({
       required this.tripId,
       required this.travelerId,
       required this.travelerName,
       required this.travelerPhone,
       required this.startTime,
       required this.status,
       required this.action,
     });

     factory TripNotificationModel.fromJson(Map<String, dynamic> json) {
       // Add logging to debug the parsing
       print('🔍 TripNotificationModel.fromJson called with: $json');
       print('🔍 Available keys: ${json.keys.toList()}');
       
       final result = TripNotificationModel(
         tripId: json['TripId'] ?? json['tripId'] ?? '',
         travelerId: json['TravelerId'] ?? json['travelerId'] ?? '',
         travelerName: json['TravelerName'] ?? json['travelerName'] ?? '',
         travelerPhone: json['TravelerPhone'] ?? json['travelerPhone'] ?? '',
         startTime: json['StartTime'] ?? json['startTime'] ?? '',
         status: json['Status'] ?? json['status'] ?? '',
         action: json['Action'] ?? json['action'] ?? '',
       );
       
       print('🔍 TripNotificationModel created:');
       print('  - tripId: ${result.tripId}');
       print('  - travelerId: ${result.travelerId}');
       print('  - travelerName: ${result.travelerName}');
       print('  - travelerPhone: ${result.travelerPhone}');
       print('  - startTime: ${result.startTime}');
       print('  - status: ${result.status}');
       print('  - action: ${result.action}');
       
       return result;
     }
   }