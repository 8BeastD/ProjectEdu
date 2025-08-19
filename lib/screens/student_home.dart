import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  Future<void> _signOut(BuildContext context) async {
    await SupabaseInit.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst); // back to splash/login
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Student • ProjectEdu')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome, ${user?.email ?? 'student'}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
