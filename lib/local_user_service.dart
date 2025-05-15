import 'package:shared_preferences/shared_preferences.dart';

class LocalUserService {
  static const _keyUserId = 'userId';
  static const _keyName = 'name';
  static const _keyEmail = 'email';

  /// Foydalanuvchini local xotiraga saqlaydi
  static Future<void> saveUser({
    required String userId,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
  }

  /// Local xotiradan foydalanuvchi ma'lumotlarini o'qiydi
  static Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final name = prefs.getString(_keyName);
    final email = prefs.getString(_keyEmail);

    if (userId != null && name != null && email != null) {
      return {
        'userId': userId,
        'name': name,
        'email': email,
      };
    }
    return null;
  }

  /// Localdagi foydalanuvchi ma'lumotlarini o‘chiradi (logout paytida)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
  }

  /// Foydalanuvchi login qilinganmi yoki yo‘q
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserId);
  }
}
