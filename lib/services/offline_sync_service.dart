import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pro/models/supporter_phone_model.dart';
import 'package:pro/services/offline_database_service.dart';
import 'package:pro/core/API/dio_consumer.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/core/errors/Exceptions.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final OfflineDatabaseService _databaseService = OfflineDatabaseService();
  DioConsumer? _apiConsumer;

  // الإندبوينت لجلب أرقام هواتف الترافيلر
  static const String _travelerSupportersPhonesEndpoint =
      '/Offline/Supporters-Phones';

  // الإندبوينت لجلب أرقام هواتف مؤيدي الطفل
  static const String _kidSupportersEndpoint = EndPoint.kidSupportersMine;

  // التحقق من الاتصال بالإنترنت
  Future<bool> _isConnected() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      log('❌ Error checking connectivity: $e');
      return false;
    }
  }

  // جلب أرقام الهواتف من الإندبوينت (ترافيلر أو طفل)
  Future<List<SupporterPhoneModel>> _fetchSupporterPhonesFromAPI(
      String endpoint) async {
    try {
      log('🔄 Fetching supporter phones from API from $endpoint...');

      // تهيئة DioConsumer إذا لم يكن مهيأ
      _apiConsumer ??= getIt<DioConsumer>();

      // التحقق من وجود الـ token
      final token = await CacheHelper.getData(key: ApiKey.token);
      log('🔑 Token check: ${token != null ? 'Found' : 'Not found'}');
      if (token != null) {
        log('🔑 Token preview: ${token.toString().substring(0, 20)}...');
      }

      log('🔗 Making request to: $endpoint');

      final response = await _apiConsumer!.get(endpoint);

      log('📡 Response received: $response');

      List<SupporterPhoneModel> supporters = [];

      if (response is Map<String, dynamic>) {
        if (response.containsKey('supportersPhones') &&
            response['supportersPhones'] is List) {
          // Case 1: Old /Offline/Supporters-Phones format (Traveler's default)
          final List<dynamic> phones = response['supportersPhones'];
          final String? fullName = response['fullName']?.toString();
          supporters = phones.map((phoneData) {
            return SupporterPhoneModel(
              supporterId:
                  '', // Supporter ID is not in this specific response structure
              supporterName: fullName ?? '',
              phoneNumber: phoneData.toString(),
              email: null,
              lastUpdated: DateTime.now(),
              isActive: true,
            );
          }).toList();
          log('✅ Fetched ${supporters.length} supporter phones from API (from supportersPhones array)');
        } else if (response.containsKey('supporters') &&
            response['supporters'] is List) {
          // Case 2: Kid Supporters format (or similar list nested under 'supporters')
          final List<dynamic> data = response['supporters'];
          supporters = data
              .map((jsonMap) =>
                  SupporterPhoneModel.fromJson(jsonMap as Map<String, dynamic>))
              .toList();
          log('✅ Fetched ${supporters.length} supporter phones from API (nested data from \'supporters\')');
        } else if (response.containsKey('data') && response['data'] is List) {
          // Case 3: Generic nested data under 'data'
          final List<dynamic> data = response['data'];
          supporters = data
              .map((jsonMap) =>
                  SupporterPhoneModel.fromJson(jsonMap as Map<String, dynamic>))
              .toList();
          log('✅ Fetched ${supporters.length} supporter phones from API (nested data from \'data\')');
        } else {
          log('❌ API Error: Unexpected response structure from $endpoint: $response');
          throw Exception(
              'Failed to fetch supporter phones: Unexpected response structure');
        }
      } else if (response is List) {
        // Direct list response
        supporters = response
            .map((jsonMap) =>
                SupporterPhoneModel.fromJson(jsonMap as Map<String, dynamic>))
            .toList();
        log('✅ Fetched ${supporters.length} supporter phones from API (direct list)');
      } else {
        log('❌ API Error: Unexpected response type from $endpoint: ${response.runtimeType}');
        throw Exception(
            'Failed to fetch supporter phones: Unexpected response type');
      }
      return supporters;
    } on ServerException catch (e) {
      log('❌ Server Exception from $endpoint: ${e.errModel.description} (Code: ${e.errModel.code})');
      log('❌ Server Error Details from $endpoint: ${e.errModel.errorMessage ?? 'No error message'}');
      rethrow;
    } catch (e) {
      log('❌ Error fetching supporter phones from $endpoint: $e');
      log('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // مزامنة أرقام هواتف الترافيلر
  Future<bool> syncTravelerSupporterPhones({bool forceSync = false}) async {
    try {
      // التحقق من الاتصال
      if (!await _isConnected()) {
        log('⚠️ No internet connection available for traveler supporter sync');
        return false;
      }

      // التحقق من آخر مزامنة (إذا لم تكن مزامنة إجبارية)
      if (!forceSync) {
        final lastSync =
            await _databaseService.getLastSyncTime('traveler_supporter_phones');
        if (lastSync != null) {
          final timeSinceLastSync = DateTime.now().difference(lastSync);
          // مزامنة كل ساعة فقط
          if (timeSinceLastSync.inHours < 1) {
            log('⏰ Traveler supporter phones last sync was ${timeSinceLastSync.inMinutes} minutes ago, skipping...');
            return true;
          }
        }
      }

      log('🔄 Starting traveler supporter phones sync...');

      // جلب البيانات من الإندبوينت الخاص بالترافيلر
      final supporters =
          await _fetchSupporterPhonesFromAPI(_travelerSupportersPhonesEndpoint);

      if (supporters.isEmpty) {
        log('⚠️ No traveler supporter phones received from API');
        return false;
      }

      // حفظ البيانات محلياً
      await _databaseService
          .insertSupporterPhones(supporters); // Reuse existing insert method

      // طباعة محتوى اللوكال داتابيز بعد الحفظ
      final localPhones = await _databaseService.getAllSupporterPhones();
      log('📦 Local DB - Traveler Supporter Phones after sync:');
      for (final phone in localPhones) {
        log('• ${phone.supporterName} | ${phone.phoneNumber} | ${phone.email ?? '-'} | Updated: ${phone.lastUpdated} | Active: ${phone.isActive}');
      }

      // حفظ وقت المزامنة
      await _databaseService.saveLastSyncTime('traveler_supporter_phones');

      log('✅ Traveler supporter sync completed successfully: ${supporters.length} phones saved');
      return true;
    } on ServerException catch (e) {
      log('❌ Server Exception during traveler supporter sync: ${e.errModel.description} (Code: ${e.errModel.code})');
      log('❌ Server Error Details for traveler supporter sync: ${e.errModel.errorMessage ?? 'No error message'}');
      return false;
    } catch (e) {
      log('❌ Traveler supporter sync failed: $e');
      log('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  // جلب أرقام هواتف الترافيلر (من المحلي أولاً، ثم من الإندبوينت إذا لزم الأمر)
  Future<List<SupporterPhoneModel>> getTravelerSupporterPhones(
      {bool forceRefresh = false}) async {
    try {
      // جلب من قاعدة البيانات المحلية
      List<SupporterPhoneModel> localPhones =
          await _databaseService.getAllSupporterPhones();
      // TODO: Needs to filter by user type if we store both kid and traveler in same table
      // For now, assume all in DB are traveler supporters, or adjust filtering if necessary

      // إذا كانت قاعدة البيانات فارغة أو طلب تحديث إجباري
      if (localPhones.isEmpty || forceRefresh) {
        log('🔄 Local database for traveler supporters is empty or force refresh requested, syncing...');

        final syncSuccess =
            await syncTravelerSupporterPhones(forceSync: forceRefresh);
        if (syncSuccess) {
          // جلب البيانات المحدثة
          localPhones = await _databaseService.getAllSupporterPhones();
        }
      }

      return localPhones;
    } catch (e) {
      log('❌ Error getting traveler supporter phones: $e');
      return [];
    }
  }

  // مزامنة أرقام هواتف مؤيدي الطفل
  Future<bool> syncKidSupporterPhones({bool forceSync = false}) async {
    try {
      // التحقق من الاتصال
      if (!await _isConnected()) {
        log('⚠️ No internet connection available for kid supporter sync');
        return false;
      }

      // التحقق من آخر مزامنة (إذا لم تكن مزامنة إجبارية)
      if (!forceSync) {
        final lastSync =
            await _databaseService.getLastSyncTime('kid_supporter_phones');
        if (lastSync != null) {
          final timeSinceLastSync = DateTime.now().difference(lastSync);
          // مزامنة كل ساعة فقط
          if (timeSinceLastSync.inHours < 1) {
            log('⏰ Kid supporter phones last sync was ${timeSinceLastSync.inMinutes} minutes ago, skipping...');
            return true;
          }
        }
      }

      log('🔄 Starting kid supporter phones sync...');

      // جلب البيانات من الإندبوينت الخاص بالطفل
      final supporters =
          await _fetchSupporterPhonesFromAPI(_kidSupportersEndpoint);

      if (supporters.isEmpty) {
        log('⚠️ No kid supporter phones received from API');
        return false;
      }

      // حفظ البيانات محلياً
      await _databaseService
          .insertSupporterPhones(supporters); // Reuse existing insert method

      // طباعة محتوى اللوكال داتابيز بعد الحفظ
      final localPhones = await _databaseService.getAllSupporterPhones();
      log('📦 Local DB - Kid Supporter Phones after sync:');
      for (final phone in localPhones) {
        log('• ${phone.supporterName} | ${phone.phoneNumber} | ${phone.email ?? '-'} | Updated: ${phone.lastUpdated} | Active: ${phone.isActive}');
      }

      // حفظ وقت المزامنة
      await _databaseService.saveLastSyncTime('kid_supporter_phones');

      log('✅ Kid supporter sync completed successfully: ${supporters.length} phones saved');
      return true;
    } on ServerException catch (e) {
      log('❌ Server Exception during kid supporter sync: ${e.errModel.description} (Code: ${e.errModel.code})');
      log('❌ Server Error Details for kid supporter sync: ${e.errModel.errorMessage ?? 'No error message'}');
      return false;
    } catch (e) {
      log('❌ Kid supporter sync failed: $e');
      log('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  // جلب أرقام هواتف مؤيدي الطفل (من المحلي أولاً، ثم من الإندبوينت إذا لزم الأمر)
  Future<List<SupporterPhoneModel>> getKidSupporterPhones(
      {bool forceRefresh = false}) async {
    try {
      List<SupporterPhoneModel> localPhones =
          await _databaseService.getAllSupporterPhones();
      // TODO: Needs to filter by user type if we store both kid and traveler in same table
      // For now, filter by endpoint used for sync (assuming kid supporters will have a valid supporterId that traveler ones might not, or vice versa)
      // A better approach would be to add a 'userType' field to SupporterPhoneModel and filter based on that.
      // For now, filtering based on supporterId being present (assuming API returns it for kid supporters and not for simple traveler phones)
      localPhones =
          localPhones.where((phone) => phone.supporterId.isNotEmpty).toList();

      if (localPhones.isEmpty || forceRefresh) {
        log('🔄 Local database for kid supporters is empty or force refresh requested, syncing...');
        final syncSuccess =
            await syncKidSupporterPhones(forceSync: forceRefresh);
        if (syncSuccess) {
          localPhones = await _databaseService.getAllSupporterPhones();
          localPhones = localPhones
              .where((phone) => phone.supporterId.isNotEmpty)
              .toList();
        }
      }
      return localPhones;
    } catch (e) {
      log('❌ Error getting kid supporter phones: $e');
      return [];
    }
  }

  // البحث في أرقام الهواتف
  Future<List<SupporterPhoneModel>> searchSupporterPhones(String query) async {
    try {
      return await _databaseService.searchSupporterPhones(query);
    } catch (e) {
      log('❌ Error searching supporter phones: $e');
      return [];
    }
  }

  // جلب رقم هاتف مؤيد معين
  Future<SupporterPhoneModel?> getSupporterPhone(String supporterId) async {
    try {
      return await _databaseService.getSupporterPhone(supporterId);
    } catch (e) {
      log('❌ Error getting supporter phone: $e');
      return null;
    }
  }

  // تحديث رقم هاتف محلياً
  Future<bool> updateSupporterPhone(SupporterPhoneModel supporter) async {
    try {
      await _databaseService.updateSupporterPhone(supporter);
      return true;
    } catch (e) {
      log('❌ Error updating supporter phone: $e');
      return false;
    }
  }

  // حذف جميع البيانات المحلية
  Future<bool> clearLocalData() async {
    try {
      await _databaseService.deleteAllSupporterPhones();
      log('✅ Local data cleared successfully');
      return true;
    } catch (e) {
      log('❌ Error clearing local data: $e');
      return false;
    }
  }

  // الحصول على إحصائيات قاعدة البيانات المحلية
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final phones = await _databaseService.getAllSupporterPhones();
      final lastSync = await _databaseService.getLastSyncTime(
          'traveler_supporter_phones'); // Keep this for traveler stats

      return {
        'total_phones': phones.length,
        'last_sync': lastSync?.toIso8601String(),
      };
    } catch (e) {
      log('❌ Error getting database stats: $e');
      return {'total_phones': 0, 'last_sync': null};
    }
  }
}
