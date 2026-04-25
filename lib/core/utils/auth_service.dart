import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles Firebase authentication for Watch Together feature.
/// Supports both anonymous and named users.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ensure user is authenticated (anonymous if no account).
  static Future<User> ensureAuthenticated() async {
    if (_auth.currentUser != null) return _auth.currentUser!;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// Current user UID, or empty string if not authenticated.
  static String get currentUid => _auth.currentUser?.uid ?? '';

  /// Current display name, falling back to a generated name.
  static String get displayName {
    final user = _auth.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    // Generate a short name from UID
    final uid = currentUid;
    if (uid.isEmpty) return 'Watcher';
    return 'Watcher #${uid.substring(0, 4).toUpperCase()}';
  }

  /// Update the user's display name.
  static Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    // Also persist locally for faster access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('watch_display_name', name);
  }

  /// Get saved display name from local storage.
  static Future<String?> getSavedDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('watch_display_name');
  }

  /// Check if user is authenticated.
  static bool get isAuthenticated => _auth.currentUser != null;
}
