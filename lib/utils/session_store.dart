import 'package:shared_preferences/shared_preferences.dart';

class SessionCurrent {
  final String email;
  final String role;
  const SessionCurrent(this.email, this.role);
}

class SessionStore {
  static const _kEmail = 'pe.email';
  static const _kRole  = 'pe.role';

  /// Save normalized values (trim + lowercase).
  static Future<void> save({required String email, required String role}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kEmail, email.trim().toLowerCase());
    await p.setString(_kRole, role.trim().toLowerCase());
  }

  /// Quick getters (handy when you only need one field)
  static Future<String?> getEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail);
  }

  static Future<String?> getRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRole);
  }

  /// Full current “session” (email + role)
  static Future<SessionCurrent> current() async {
    final p = await SharedPreferences.getInstance();
    final email = (p.getString(_kEmail) ?? '').trim().toLowerCase();
    final role  = (p.getString(_kRole)  ?? 'student').trim().toLowerCase();
    return SessionCurrent(email, role);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kEmail);
    await p.remove(_kRole);
  }
}
