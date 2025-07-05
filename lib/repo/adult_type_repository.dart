import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/models/adult_type_model.dart';

class AdultTypeRepository {
  final String baseUrl = 'https://followsafe.runasp.net';

  Future<AdultTypeResponse> changeAdultType({
    required String userId,
    required String adultType,
  }) async {
    // استخدام EndPoint.adultType من ApiKey
    final url = Uri.parse(EndPoint.adultType);

    print("Debug - Sending request to: $url");
    print("Debug - adultType: $adultType");

    try {
      // الحصول على رمز التوثيق (token) من CacheHelper
      final token = CacheHelper.getData(key: ApiKey.token);

      if (token == null) {
        throw Exception('Token not found. Please login again.');
      }

      print("Debug - Using token: $token");

      // استخراج معرف المستخدم من الرمز المميز
      final decodedToken = JwtDecoder.decode(token);
      print("Debug - Decoded token: $decodedToken");

      // استخراج معرف المستخدم من الحقل "sub" في الرمز المميز
      final effectiveUserId = decodedToken['sub'];
      print("Debug - Extracted user ID from token: $effectiveUserId");

      if (effectiveUserId == null) {
        throw Exception('User ID not found in token. Please login again.');
      }

      // استخدام المفاتيح من ApiKey للتأكد من التوافق مع الخادم
      final requestBody = {
        ApiKey.userId: effectiveUserId, // استخدام معرف المستخدم من الرمز المميز
        ApiKey.adultType: adultType,
      };

      print("Debug - Request body: ${jsonEncode(requestBody)}");

      // إضافة رأس التوثيق
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print("Debug - Response status code: ${response.statusCode}");
      print("Debug - Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("Debug - Decoded response: $jsonResponse");
        return AdultTypeResponse.fromJson(jsonResponse);
      } else {
        print("Debug - Error response: ${response.body}");
        throw Exception(
            'Failed to change adult type: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Debug - Exception during HTTP request: $e");
      throw Exception('Failed to change adult type: $e');
    }
  }
}
