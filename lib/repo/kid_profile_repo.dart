import 'package:dio/dio.dart';
import 'package:pro/models/kid_profile_model.dart';

class KidProfileRepository {
  final Dio dio;
  KidProfileRepository(this.dio);

  Future<KidProfileModel> getKidProfile(String token) async {
    final response = await dio.get(
      'https://followsafe.runasp.net/Child/GetProfile',
      options: Options(headers: {
        "Authorization": "Bearer $token",
      }),
    );

    if (response.statusCode == 200) {
      return KidProfileModel.fromJson(response.data);
    } else {
      throw Exception("Failed to fetch profile");
    }
  }
}
