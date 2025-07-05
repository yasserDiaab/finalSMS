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

  // الإندبوينت لجلب أرقام الهواتف
  static const String _supportersPhonesEndpoint = '/Offline/Supporters-Phones';

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

  // جلب أرقام الهواتف من الإندبوينت
  Future<List<SupporterPhoneModel>> _fetchSupporterPhonesFromAPI() async {
    try {
      log('🔄 Fetching supporter phones from API...');

      // تهيئة DioConsumer إذا لم يكن مهيأ
      _apiConsumer ??= getIt<DioConsumer>();

      // التحقق من وجود الـ token
      final token = await CacheHelper.getData(key: ApiKey.token);
      log('🔑 Token check: ${token != null ? 'Found' : 'Not found'}');
      if (token != null) {
        log('🔑 Token preview: ${token.toString().substring(0, 20)}...');
      }

      log('🔗 Making request to: $_supportersPhonesEndpoint');

      final response = await _apiConsumer!.get(_supportersPhonesEndpoint);

      log('📡 Response received: $response');

      // معالجة الاستجابة الجديدة
      if (response is Map<String, dynamic> &&
          response.containsKey('supportersPhones')) {
        final List<dynamic> phones = response['supportersPhones'];
        final String? fullName = response['fullName']?.toString();
        final List<SupporterPhoneModel> supporters = phones.map((phone) {
          return SupporterPhoneModel(
            supporterId: '',
            supporterName: fullName ?? '',
            phoneNumber: phone.toString(),
            email: null,
            lastUpdated: DateTime.now(),
            isActive: true,
          );
        }).toList();
        log('✅ Fetched ${supporters.length} supporter phones from API (from supportersPhones array)');
        return supporters;
      }

      // باقي الكود كما هو (للتوافق مع أي استجابة أخرى)
      if (response != null) {
        if (response is List) {
          final List<SupporterPhoneModel> supporters = response
              .map((json) => SupporterPhoneModel.fromJson(json))
              .toList();

          log('✅ Fetched ${supporters.length} supporter phones from API');
          return supporters;
        } else if (response is Map<String, dynamic>) {
          if (response.containsKey('data') && response['data'] is List) {
            final List<dynamic> data = response['data'];
            final List<SupporterPhoneModel> supporters =
                data.map((json) => SupporterPhoneModel.fromJson(json)).toList();

            log('✅ Fetched ${supporters.length} supporter phones from API (nested data)');
            return supporters;
          } else {
            log('❌ API Error: Unexpected response structure: $response');
            throw Exception(
                'Failed to fetch supporter phones: Unexpected response structure');
          }
        } else {
          log('❌ API Error: Unexpected response type: ${response.runtimeType}');
          throw Exception(
              'Failed to fetch supporter phones: Unexpected response type');
        }
      } else {
        log('❌ API Error: No response data');
        throw Exception('Failed to fetch supporter phones: No response data');
      }
    } on ServerException catch (e) {
      log('❌ Server Exception: ${e.errModel.description} (Code: ${e.errModel.code})');
      log('❌ Server Error Details: ${e.errModel.errorMessage ?? 'No error message'}');
      rethrow;
    } catch (e) {
      log('❌ Error fetching supporter phones: $e');
      log('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // مزامنة أرقام الهواتف
  Future<bool> syncSupporterPhones({bool forceSync = false}) async {
    try {
      // التحقق من الاتصال
      if (!await _isConnected()) {
        log('⚠️ No internet connection available');
        return false;
      }

      // التحقق من آخر مزامنة (إذا لم تكن مزامنة إجبارية)
      if (!forceSync) {
        final lastSync =
            await _databaseService.getLastSyncTime('supporter_phones');
        if (lastSync != null) {
          final timeSinceLastSync = DateTime.now().difference(lastSync);
          // مزامنة كل ساعة فقط
          if (timeSinceLastSync.inHours < 1) {
            log('⏰ Last sync was ${timeSinceLastSync.inMinutes} minutes ago, skipping...');
            return true;
          }
        }
      }

      log('🔄 Starting supporter phones sync...');

      // جلب البيانات من الإندبوينت
      final supporters = await _fetchSupporterPhonesFromAPI();

      if (supporters.isEmpty) {
        log('⚠️ No supporter phones received from API');
        return false;
      }

      // حفظ البيانات محلياً
      await _databaseService.insertSupporterPhones(supporters);

      // طباعة محتوى اللوكال داتابيز بعد الحفظ
      final localPhones = await _databaseService.getAllSupporterPhones();
      log('📦 Local DB - Supporter Phones:');
      for (final phone in localPhones) {
        log('• ${phone.supporterName} | ${phone.phoneNumber} | ${phone.email ?? "-"} | Updated: ${phone.lastUpdated} | Active: ${phone.isActive}');
      }

      // حفظ وقت المزامنة
      await _databaseService.saveLastSyncTime('supporter_phones');

      log('✅ Sync completed successfully: ${supporters.length} phones saved');
      return true;
    } on ServerException catch (e) {
      log('❌ Server Exception during sync: ${e.errModel.description} (Code: ${e.errModel.code})');
      log('❌ Server Error Details: ${e.errModel.errorMessage ?? 'No error message'}');
      return false;
    } catch (e) {
      log('❌ Sync failed: $e');
      log('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  // جلب أرقام الهواتف (من المحلي أولاً، ثم من الإندبوينت إذا لزم الأمر)
  Future<List<SupporterPhoneModel>> getSupporterPhones(
      {bool forceRefresh = false}) async {
    try {
      // جلب من قاعدة البيانات المحلية
      List<SupporterPhoneModel> localPhones =
          await _databaseService.getAllSupporterPhones();

      // إذا كانت قاعدة البيانات فارغة أو طلب تحديث إجباري
      if (localPhones.isEmpty || forceRefresh) {
        log('🔄 Local database is empty or force refresh requested, syncing...');

        final syncSuccess = await syncSupporterPhones(forceSync: forceRefresh);
        if (syncSuccess) {
          // جلب البيانات المحدثة
          localPhones = await _databaseService.getAllSupporterPhones();
        }
      }

      return localPhones;
    } catch (e) {
      log('❌ Error getting supporter phones: $e');
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
      final lastSync =
          await _databaseService.getLastSyncTime('supporter_phones');

      return {
        'totalPhones': phones.length,
        'lastSyncTime': lastSync?.toIso8601String(),
        'isConnected': await _isConnected(),
      };
    } catch (e) {
      log('❌ Error getting database stats: $e');
      return {
        'totalPhones': 0,
        'lastSyncTime': null,
        'isConnected': false,
      };
    }
  }
}
