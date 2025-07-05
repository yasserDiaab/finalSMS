class AdultTypeResponse {
  final String message;

  AdultTypeResponse({required this.message});

  factory AdultTypeResponse.fromJson(Map<String, dynamic> json) {
    return AdultTypeResponse(
      message: json['message'] ?? '',
    );
  }
}
