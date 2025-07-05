class ErrorModel {
  final int? statusCode;
  final String? errorMessage;
  final String code;
  final String description;

  ErrorModel({
    this.statusCode,
    this.errorMessage,
    required this.code,
    required this.description,
  });

  factory ErrorModel.fromJson(Map<String, dynamic> jsonData) {
    return ErrorModel(
      code: jsonData["code"].toString(),
      description: jsonData["description"].toString(),
    );
  }
}
