import 'package:dio/dio.dart';
import 'api_consumer.dart';

class ApiService implements ApiConsumer {
  final Dio _dio = Dio();

  @override
  Future<dynamic> get(String path,
      {Object? data, Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<dynamic> post(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      bool isFromData = false}) async {
    final response =
        await _dio.post(path, data: data, queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<dynamic> patch(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      bool isFromData = false}) async {
    final response =
        await _dio.patch(path, data: data, queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<dynamic> delete(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      bool isFromData = false}) async {
    final response =
        await _dio.delete(path, data: data, queryParameters: queryParameters);
    return response.data;
  }
}
