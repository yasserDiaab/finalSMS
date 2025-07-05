import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  //! Initialize cache
  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  //! Get String Data
  static String? getDataString({required String key}) {
    return sharedPreferences.getString(key);
  }

  //! Save Data Safely
  static Future<bool> saveData(
      {required String key, required dynamic value}) async {
    if (value == null)
      return Future.value(false); // Prevent storing null values

    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    } else if (value is String) {
      return await sharedPreferences.setString(key, value);
    } else if (value is int) {
      return await sharedPreferences.setInt(key, value);
    } else if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    } else {
      return Future.value(false); // Unsupported type
    }
  }

  //! Get Data
  static dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  //! Remove Data
  static Future<bool> removeData({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  //! Check if key exists
  static bool containsKey({required String key}) {
    return sharedPreferences.containsKey(key);
  }

  //! Clear All Data
  static Future<bool> clearData() async {
    return await sharedPreferences.clear();
  }

  //! Save Default Mode
  static Future<void> saveDefaultMode(String mode) async {
    await sharedPreferences.setString("default_mode", mode);
  }

  //! Get Default Mode
  static String? getDefaultMode() {
    return sharedPreferences.getString("default_mode");
  }
}
