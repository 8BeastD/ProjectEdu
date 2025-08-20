import 'package:flutter/material.dart';
import '../repo/supabase_projects_repo.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ProjectsRepo.instance;
    final g = await repo.getGroup(widget.groupId);
    final m = await repo.groupMembers(widget.groupId);
    setState(() {
      _group = g;
      _members = m;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_group!['name'] ?? 'Group', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            Chip(label: Text('Status: ${_group!['status']}')),
            const SizedBox(width: 8),
            Chip(label: Text('Teacher: ${_group!['teacher_status'] ?? 'pending'}')),
          ]),
          const SizedBox(height: 16),
          const Text('Members', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._members.map((m) {
            final prof = m['profile'] as Map<String, dynamic>?;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(prof?['full_name'] ?? m['user_id']),
              subtitle: Text('${prof?['email'] ?? ''} • ${m['role_in_group']}'),
            );
          }),
        ],
      ),
    );
  }
}
