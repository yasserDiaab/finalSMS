class ActiveTripModel {
  final String tripId;
  final String travelerId;
  final String travelerName;
  final String travelerPhone;
  final String startTime;
  final String status;
  final String action;

  ActiveTripModel({
    required this.tripId,
    required this.travelerId,
    required this.travelerName,
    required this.travelerPhone,
    required this.startTime,
    required this.status,
    required this.action,
  });

  factory ActiveTripModel.fromJson(Map<String, dynamic> json) {
    return ActiveTripModel(
      tripId: json['tripId'],
      travelerId: json['travelerId'],
      travelerName: json['travelerName'],
      travelerPhone: json['travelerPhone'],
      startTime: json['startTime'],
      status: json['status'],
      action: json['action'],
    );
  }
}
