import 'package:dio/dio.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/core/API/api_interceptor.dart';
import 'package:pro/core/errors/Exceptions.dart';

class DioConsumer extends ApiConsumer {
  final Dio dio;

  DioConsumer({required this.dio}) {
    dio.options.baseUrl = EndPoint.baseUrl;
    dio.interceptors.add(ApiInterceptor());
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  @override
  Future delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    try {
      final response = await dio.delete(
        path,
        data: isFromData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }

  @override
  Future get(String path,
      {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }

  @override
  Future patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    try {
      final response = await dio.patch(
        path,
        data: isFromData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }

  @override
  Future post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: isFromData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      final response = await post(
        '/generate-otp',
        data: {"email": email},
      );
      print("OTP Sent: $response");
    } catch (e) {
      print("Error sending OTP: $e");
      throw e;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await post(
        '/verify-otp',
        data: {"email": email, "otp": otp},
      );
      return response['success'] == true;
    } catch (e) {
      print("OTP verification failed: $e");
      return false;
    }
  }

  // ✅ إضافة adultType عند إرسال البيانات
  Future<void> updateAdultType(String email, String adultType) async {
    try {
      final response = await post(
        '/update-adult-type',
        data: {"email": email, "adultType": adultType},
      );
      print("Adult Type Updated: $response");
    } catch (e) {
      print("Error updating adult type: $e");
      throw e;
    }
  }
}
