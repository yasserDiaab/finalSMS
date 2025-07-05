import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/offline_sync/offline_sync_state.dart';
import 'package:pro/models/supporter_phone_model.dart';
import 'package:pro/services/offline_sync_service.dart';

class OfflineSyncCubit extends Cubit<OfflineSyncState> {
  final OfflineSyncService _syncService = OfflineSyncService();

  OfflineSyncCubit() : super(OfflineSyncInitial());

  // تحميل أرقام الهواتف (من المحلي أولاً)
  Future<void> loadSupporterPhones({bool forceRefresh = false}) async {
    try {
      emit(OfflineSyncLoading());
      log('🔄 Loading supporter phones...');

      final phones =
          await _syncService.getSupporterPhones(forceRefresh: forceRefresh);
      final stats = await _syncService.getDatabaseStats();

      if (phones.isNotEmpty) {
        final lastSync = stats['lastSyncTime'] != null
            ? DateTime.parse(stats['lastSyncTime'])
            : DateTime.now();

        emit(OfflineSyncSuccess(
          supporterPhones: phones,
          message: 'تم تحميل ${phones.length} رقم هاتف',
          lastSyncTime: lastSync,
        ));
        log('✅ Loaded ${phones.length} supporter phones');
      } else {
        emit(const OfflineSyncFailure('لا توجد أرقام هواتف محفوظة'));
        log('❌ No supporter phones found');
      }
    } catch (e) {
      log('❌ Error loading supporter phones: $e');
      emit(OfflineSyncFailure('فشل في تحميل أرقام الهواتف: $e'));
    }
  }

  // مزامنة مع الإندبوينت
  Future<void> syncWithServer({bool forceSync = false}) async {
    try {
      emit(OfflineSyncLoading());
      log('🔄 Syncing with server...');

      final success =
          await _syncService.syncSupporterPhones(forceSync: forceSync);

      if (success) {
        // إعادة تحميل البيانات بعد المزامنة
        await loadSupporterPhones();
      } else {
        // إذا فشلت المزامنة، جرب تحميل البيانات المحلية
        final cachedPhones = await _syncService.getSupporterPhones();
        if (cachedPhones.isNotEmpty) {
          emit(OfflineSyncNoConnection(
            cachedPhones: cachedPhones,
            message: 'لا يوجد اتصال بالإنترنت، تم عرض البيانات المحفوظة',
          ));
        } else {
          emit(const OfflineSyncFailure(
              'فشل في المزامنة ولا توجد بيانات محفوظة'));
        }
      }
    } catch (e) {
      log('❌ Error syncing with server: $e');
      emit(OfflineSyncFailure('فشل في المزامنة: $e'));
    }
  }

  // البحث في أرقام الهواتف
  Future<void> searchSupporterPhones(String query) async {
    try {
      if (query.trim().isEmpty) {
        // إذا كان البحث فارغ، اعرض جميع الأرقام
        await loadSupporterPhones();
        return;
      }

      emit(OfflineSyncLoading());
      log('🔍 Searching for: $query');

      final results = await _syncService.searchSupporterPhones(query);

      emit(OfflineSyncSearchResult(
        searchResults: results,
        query: query,
      ));

      log('✅ Found ${results.length} results for: $query');
    } catch (e) {
      log('❌ Error searching: $e');
      emit(OfflineSyncFailure('فشل في البحث: $e'));
    }
  }

  // جلب رقم هاتف مؤيد معين
  Future<SupporterPhoneModel?> getSupporterPhone(String supporterId) async {
    try {
      return await _syncService.getSupporterPhone(supporterId);
    } catch (e) {
      log('❌ Error getting supporter phone: $e');
      return null;
    }
  }

  // تحديث رقم هاتف
  Future<void> updateSupporterPhone(SupporterPhoneModel supporter) async {
    try {
      final success = await _syncService.updateSupporterPhone(supporter);
      if (success) {
        // إعادة تحميل البيانات
        await loadSupporterPhones();
        log('✅ Supporter phone updated successfully');
      } else {
        emit(const OfflineSyncFailure('فشل في تحديث رقم الهاتف'));
      }
    } catch (e) {
      log('❌ Error updating supporter phone: $e');
      emit(OfflineSyncFailure('فشل في التحديث: $e'));
    }
  }

  // مسح جميع البيانات المحلية
  Future<void> clearLocalData() async {
    try {
      emit(OfflineSyncLoading());
      log('🗑️ Clearing local data...');

      final success = await _syncService.clearLocalData();

      if (success) {
        emit(OfflineSyncSuccess(
          supporterPhones: [],
          message: 'تم مسح جميع البيانات المحلية',
          lastSyncTime: DateTime.now(),
        ));
        log('✅ Local data cleared successfully');
      } else {
        emit(const OfflineSyncFailure('فشل في مسح البيانات المحلية'));
      }
    } catch (e) {
      log('❌ Error clearing local data: $e');
      emit(OfflineSyncFailure('فشل في المسح: $e'));
    }
  }

  // الحصول على إحصائيات قاعدة البيانات
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      return await _syncService.getDatabaseStats();
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
