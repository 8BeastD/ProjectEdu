import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';
import '../utils/session_store.dart'; // keeps email/role

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _row;
  bool _loading = true;
  String _email = '';
  String _role = 'student';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final saved = await SessionStore.current();
    _email = (saved.email).trim().toLowerCase();
    _role = saved.role; // just for the badge label

    if (_email.isEmpty) {
      setState(() => _loading = false);
      _toast('No session email found. Please log in again.', true);
      return;
    }

    try {
      final client = SupabaseInit.client;

      // ✅ No type arg on select(); fetch by unique email only.
      final r = await client
          .from('directory_people')
          .select(
          'email, full_name, university_id, role, phone, department, hostel, group_no, avatar_url')
          .eq('email', _email)
          .maybeSingle();

      setState(() {
        _row = r; // can be null if not found
        _loading = false;
      });

      if (r == null) {
        _toast('No profile found for $_email', true);
      }
    } catch (e) {
      setState(() => _loading = false);
      _toast('Failed to load profile: $e', true);
    }
  }

  Future<void> _signOut() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _toast(String msg, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF2563EB);
    const brandLight = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _row == null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No profile found'),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [brand, brandLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.person,
                        size: 44, color: brand),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_row!['full_name'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _RolePill(text: _roleLabel(_role)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _email.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 280.ms)
                .moveY(begin: 10, end: 0),
            const SizedBox(height: 16),

            // Sections
            _Section(
              title: 'Basic Information',
              children: [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Name',
                  value: (_row!['full_name'] ?? '').toString(),
                ),
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Category',
                  value: _row!['role'] == 'student'
                      ? 'Group: ${(_row!['group_no'] ?? 'N/A').toString()}'
                      : (_row!['role'] == 'teacher'
                      ? 'Supervisor'
                      : 'Coordinator'),
                ),
                _InfoRow(
                  icon: Icons.call_outlined,
                  label: 'Contact Number',
                  value: (_row!['phone'] ?? 'N/A').toString(),
                ),
                _InfoRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: _email,
                ),
                if ((_row!['university_id'] ?? '')
                    .toString()
                    .isNotEmpty)
                  _InfoRow(
                    icon: Icons.numbers_rounded,
                    label: 'University ID',
                    value:
                    (_row!['university_id'] ?? '').toString(),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            _Section(
              title: 'Institute Details',
              children: [
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'Department',
                  value: (_row!['department'] ?? 'N/A').toString(),
                ),
                _InfoRow(
                  icon: Icons.location_city_outlined,
                  label: 'Hostel / Block',
                  value: (_row!['hostel'] ?? 'N/A').toString(),
                ),
              ],
            ),

            const SizedBox(height: 26),
            TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.power_settings_new_rounded),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 18),
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'teacher':
        return 'Supervisor';
      case 'admin':
        return 'Coordinator';
      default:
        return 'Student';
    }
  }
}

class _RolePill extends StatelessWidget {
  final String text;
  const _RolePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: const [
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
      dense: true,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
