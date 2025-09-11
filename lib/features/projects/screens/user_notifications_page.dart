import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectedu/utils/session_store.dart';

class UserNotificationsPage extends StatefulWidget {
  const UserNotificationsPage({super.key});
  @override
  State<UserNotificationsPage> createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  String _email = '';
  List<Map<String,dynamic>> _rows = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cur = await SessionStore.current();
    _email = cur.email;
    try {
      final rs = await _client
          .from('user_notifications')
          .select()
          .eq('recipient_email', _email)
          .order('created_at', ascending: false);
      _rows = List<Map<String,dynamic>>.from(rs);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final r = _rows[i];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.notifications)),
              title: Text((r['title'] ?? '').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text((r['message'] ?? '').toString()),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: _rows.length,
        ),
      ),
    );
  }
}
