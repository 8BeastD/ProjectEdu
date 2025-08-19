import 'package:shared_preferences/shared_preferences.dart';

class _Current {
  final String email;
  final String role;
  const _Current(this.email, this.role);
}

class SessionStore {
  static const _kEmail = 'pe.email';
  static const _kRole = 'pe.role';

  static Future<void> save({required String email, required String role}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kEmail, email);
    await p.setString(_kRole, role);
  }

  static Future<_Current> current() async {
    final p = await SharedPreferences.getInstance();
    return _Current(p.getString(_kEmail) ?? '', p.getString(_kRole) ?? 'student');
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kEmail);
    await p.remove(_kRole);
  }
}
