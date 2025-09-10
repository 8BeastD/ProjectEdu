import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectedu/utils/session_store.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeC = TextEditingController();
  bool _loading = false;
  String? _studentEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentStudent();
  }

  Future<void> _loadCurrentStudent() async {
    // use your lightweight session store
    final cur = await SessionStore.current();
    setState(() => _studentEmail = (cur.email.isNotEmpty ? cur.email : null));
  }

  @override
  void dispose() {
    _codeC.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeC.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the group code')),
      );
      return;
    }
    if (_studentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as a student first.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;

      final res = await client.rpc('join_group_with_code', params: {
        'p_code': code,
        'p_student_email': _studentEmail!,
      });

      if (res is! List || res.isEmpty) {
        throw 'RPC returned empty';
      }

      final row = (res.first as Map<String, dynamic>);
      final groupNo = row['group_no'];

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Joined Group'),
          content: Text('Success! You are now in Group #$groupNo.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // go back to previous screen
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canJoin = !_loading && (_studentEmail != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Join Group by Code')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6EAF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter the code shared by the group leader.',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeC,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Group Code',
                    hintText: 'e.g., 4F2A9C',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _studentEmail == null
                      ? 'Not signed in.'
                      : 'You are signing in as: $_studentEmail',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canJoin ? _join : null,
              icon: _loading
                  ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(_loading ? 'Joining…' : 'Join Group'),
            ),
          ),
        ],
      ),
    );
  }
}
