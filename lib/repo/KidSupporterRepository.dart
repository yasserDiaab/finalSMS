import 'dart:developer';
import 'package:pro/core/API/dio_consumer.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/models/KidAddSupporterModel.dart';

class KidSupporterRepository {
  final DioConsumer api;

  KidSupporterRepository({required this.api});

  Future<KidAddSupporterModel> addSupporterToKid(String emailOrUsername) async {
    try {
      log("KidSupporterRepository: Adding supporter to kid - $emailOrUsername");

      final response = await api.post(
        EndPoint.kidTrustedContacts,
        data: {
          "EmailOrUsername": emailOrUsername,
        },
      );

      log("KidSupporterRepository: Response received - $response");

      final model = KidAddSupporterModel.fromJson(response);
      log("KidSupporterRepository: Successfully parsed response - ${model.message}");

      return model;
    } catch (e) {
      log("KidSupporterRepository: Error occurred - $e");

      if (e.toString().contains('DioException')) {
        if (e.toString().contains('404')) {
          throw Exception('User not found');
        } else if (e.toString().contains('400')) {
          throw Exception('Invalid email or username');
        } else if (e.toString().contains('401')) {
          throw Exception('Unauthorized. Please log in again');
        } else if (e.toString().contains('500')) {
          throw Exception('Server error. Please try again later');
        }
      }

      if (e is Exception) rethrow;

      throw Exception('Failed to add supporter: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getKidSupporters() async {
    try {
      log("KidSupporterRepository: Getting kid supporters");

      final response = await api.get(EndPoint.kidSupportersMine);

      log("KidSupporterRepository: Supporters response received - $response");

      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['supporters'] != null) {
        return List<Map<String, dynamic>>.from(response['supporters']);
      } else {
        log("KidSupporterRepository: Unexpected response format");
        return [];
      }
    } catch (e) {
      log("KidSupporterRepository: Error getting supporters - $e");
      return [];
    }
  }

  Future<bool> removeSupporterFromKid(String supporterId) async {
    try {
      log("KidSupporterRepository: Removing supporter from kid - $supporterId");

      final response = await api.delete(
        "${EndPoint.kidTrustedContacts}/$supporterId",
      );

      log("KidSupporterRepository: Remove response received - $response");

      return true;
    } catch (e) {
      log("KidSupporterRepository: Error removing supporter - $e");
      return false;
    }
  }
}
