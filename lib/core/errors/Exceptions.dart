import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pro/core/errors/ErrorModel.dart';

class ServerException implements Exception {
  final ErrorModel errModel;

  ServerException({required this.errModel});
}

void handleDioExceptions(DioException e) {
  dynamic responseData = e.response?.data;

  if (responseData is String) {
    try {
      responseData = json.decode(responseData);
    } catch (error) {
      responseData = {"message": "Invalid JSON response", "code": 500};
    }
  }

  if (responseData is! Map<String, dynamic>) {
    responseData = {"message": "Unexpected response type", "code": 500};
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      throw ServerException(errModel: ErrorModel.fromJson(responseData));

    case DioExceptionType.badResponse:
      switch (e.response?.statusCode) {
        case 400:
        case 401:
        case 403:
        case 404:
        case 409:
        case 422:
        case 504:
          throw ServerException(errModel: ErrorModel.fromJson(responseData));
      }
  }
}
