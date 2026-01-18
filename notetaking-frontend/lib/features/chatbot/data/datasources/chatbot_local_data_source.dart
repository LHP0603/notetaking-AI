import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

abstract class ChatbotLocalDataSource {
  Future<String?> getSessionId();
  Future<void> cacheSessionId(String sessionId);
  Future<void> clearSessionId();
}

class ChatbotLocalDataSourceImpl implements ChatbotLocalDataSource {
  final SharedPreferences sharedPreferences;

  ChatbotLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<String?> getSessionId() async {
    try {
      return sharedPreferences.getString(AppConstants.chatSessionIdKey);
    } catch (e) {
      throw CacheException('Failed to read chat session');
    }
  }

  @override
  Future<void> cacheSessionId(String sessionId) async {
    try {
      await sharedPreferences.setString(
        AppConstants.chatSessionIdKey,
        sessionId,
      );
    } catch (e) {
      throw CacheException('Failed to cache chat session');
    }
  }

  @override
  Future<void> clearSessionId() async {
    try {
      await sharedPreferences.remove(AppConstants.chatSessionIdKey);
    } catch (e) {
      throw CacheException('Failed to clear chat session');
    }
  }
}
