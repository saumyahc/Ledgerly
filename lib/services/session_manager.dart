import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLoginTimestamp = 'login_timestamp';
  static const String _keyProfileComplete = 'profile_complete';

  // Session timeout (30 days in milliseconds)
  static const int sessionTimeout = 30 * 24 * 60 * 60 * 1000;

  /// Save user session after successful login
  static Future<void> saveUserSession({
    required int userId,
    required String userName,
    required String userEmail,
    bool profileComplete = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserEmail, userEmail);
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyLoginTimestamp, timestamp);
    await prefs.setBool(_keyProfileComplete, profileComplete);
    
    print('📱 Session - Saved user session: userId=$userId, userName=$userName, userEmail=$userEmail, profileComplete=$profileComplete');
  }

  /// Get current user session
  static Future<UserSession?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) {
      print('📱 Session - No active session found');
      return null;
    }

    final loginTimestamp = prefs.getInt(_keyLoginTimestamp) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Check if session has expired
    if (currentTime - loginTimestamp > sessionTimeout) {
      print('📱 Session - Session expired, clearing data');
      await clearUserSession();
      return null;
    }

    final userId = prefs.getInt(_keyUserId);
    final userName = prefs.getString(_keyUserName);
    final userEmail = prefs.getString(_keyUserEmail);
    final profileComplete = prefs.getBool(_keyProfileComplete) ?? false;

    if (userId == null || userName == null || userEmail == null) {
      print('📱 Session - Incomplete session data, clearing session');
      await clearUserSession();
      return null;
    }

    final session = UserSession(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      profileComplete: profileComplete,
    );
    
    print('📱 Session - Retrieved active session: $session');
    return session;
  }

  /// Update profile completion status
  static Future<void> updateProfileComplete(bool profileComplete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProfileComplete, profileComplete);
    print('📱 Session - Updated profile complete status: $profileComplete');
  }

  /// Clear user session (logout)
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyLoginTimestamp);
    await prefs.remove(_keyProfileComplete);
    print('📱 Session - Cleared user session');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final session = await getUserSession();
    return session != null;
  }

  /// Get user ID from session
  static Future<int?> getUserId() async {
    final session = await getUserSession();
    return session?.userId;
  }

  /// Extend session (update timestamp)
  static Future<void> extendSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (isLoggedIn) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_keyLoginTimestamp, timestamp);
      print('📱 Session - Extended session timestamp');
    }
  }
}

class UserSession {
  final int userId;
  final String userName;
  final String userEmail;
  final bool profileComplete;

  UserSession({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.profileComplete,
  });

  @override
  String toString() {
    return 'UserSession(userId: $userId, userName: $userName, userEmail: $userEmail, profileComplete: $profileComplete)';
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'profileComplete': profileComplete,
    };
  }
}
