import 'dart:async';
import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pro/models/supporter_phone_model.dart';

class OfflineDatabaseService {
  static final OfflineDatabaseService _instance =
      OfflineDatabaseService._internal();
  factory OfflineDatabaseService() => _instance;
  OfflineDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'followsafe_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول أرقام هواتف المؤيدين
    await db.execute('''
      CREATE TABLE supporter_phones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supporterId TEXT NOT NULL,
        supporterName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT,
        lastUpdated INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        UNIQUE(supporterId)
      )
    ''');

    // جدول لتتبع آخر تحديث
    await db.execute('''
      CREATE TABLE sync_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lastSyncTime INTEGER NOT NULL,
        syncType TEXT NOT NULL
      )
    ''');

    log('✅ Offline database created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    log('🔄 Database upgraded from version $oldVersion to $newVersion');
  }

  // حفظ رقم هاتف مؤيد
  Future<int> insertSupporterPhone(SupporterPhoneModel supporter) async {
    try {
      final db = await database;
      final result = await db.insert(
        'supporter_phones',
        supporter.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      log('✅ Supporter phone saved: ${supporter.supporterName}');
      return result;
    } catch (e) {
      log('❌ Error saving supporter phone: $e');
      rethrow;
    }
  }

  // حفظ قائمة أرقام الهواتف
  Future<void> insertSupporterPhones(
      List<SupporterPhoneModel> supporters) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        for (var supporter in supporters) {
          await txn.insert(
            'supporter_phones',
            supporter.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      log('✅ ${supporters.length} supporter phones saved');
    } catch (e) {
      log('❌ Error saving supporter phones: $e');
      rethrow;
    }
  }

  // جلب جميع أرقام الهواتف
  Future<List<SupporterPhoneModel>> getAllSupporterPhones() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'supporter_phones',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'supporterName ASC',
      );

      return List.generate(maps.length, (i) {
        return SupporterPhoneModel.fromMap(maps[i]);
      });
    } catch (e) {
      log('❌ Error getting supporter phones: $e');
      return [];
    }
  }

  // جلب رقم هاتف مؤيد معين
  Future<SupporterPhoneModel?> getSupporterPhone(String supporterId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'supporter_phones',
        where: 'supporterId = ? AND isActive = ?',
        whereArgs: [supporterId, 1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return SupporterPhoneModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      log('❌ Error getting supporter phone: $e');
      return null;
    }
  }

  // البحث في أرقام الهواتف
  Future<List<SupporterPhoneModel>> searchSupporterPhones(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'supporter_phones',
        where: '(supporterName LIKE ? OR phoneNumber LIKE ?) AND isActive = ?',
        whereArgs: ['%$query%', '%$query%', 1],
        orderBy: 'supporterName ASC',
      );

      return List.generate(maps.length, (i) {
        return SupporterPhoneModel.fromMap(maps[i]);
      });
    } catch (e) {
      log('❌ Error searching supporter phones: $e');
      return [];
    }
  }

  // تحديث رقم هاتف
  Future<int> updateSupporterPhone(SupporterPhoneModel supporter) async {
    try {
      final db = await database;
      final result = await db.update(
        'supporter_phones',
        supporter.toMap(),
        where: 'supporterId = ?',
        whereArgs: [supporter.supporterId],
      );
      log('✅ Supporter phone updated: ${supporter.supporterName}');
      return result;
    } catch (e) {
      log('❌ Error updating supporter phone: $e');
      rethrow;
    }
  }

  // حذف رقم هاتف
  Future<int> deleteSupporterPhone(String supporterId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'supporter_phones',
        where: 'supporterId = ?',
        whereArgs: [supporterId],
      );
      log('✅ Supporter phone deleted: $supporterId');
      return result;
    } catch (e) {
      log('❌ Error deleting supporter phone: $e');
      rethrow;
    }
  }

  // حذف جميع أرقام الهواتف
  Future<int> deleteAllSupporterPhones() async {
    try {
      final db = await database;
      final result = await db.delete('supporter_phones');
      log('✅ All supporter phones deleted');
      return result;
    } catch (e) {
      log('❌ Error deleting all supporter phones: $e');
      rethrow;
    }
  }

  // حفظ وقت آخر مزامنة
  Future<void> saveLastSyncTime(String syncType) async {
    try {
      final db = await database;
      await db.insert(
        'sync_status',
        {
          'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
          'syncType': syncType,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      log('✅ Last sync time saved: $syncType');
    } catch (e) {
      log('❌ Error saving sync time: $e');
    }
  }

  // جلب وقت آخر مزامنة
  Future<DateTime?> getLastSyncTime(String syncType) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sync_status',
        where: 'syncType = ?',
        whereArgs: [syncType],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return DateTime.fromMillisecondsSinceEpoch(maps.first['lastSyncTime']);
      }
      return null;
    } catch (e) {
      log('❌ Error getting last sync time: $e');
      return null;
    }
  }

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      log('✅ Database closed');
    }
  }
}
