import 'package:flutter/material.dart';
import '../repo/supabase_projects_repo.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  List<Map<String, dynamic>> _projects = [];
  String? _projectId;
  List<Map<String, dynamic>> _groups = [];
  String? _groupId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final list = await ProjectsRepo.instance.listProjects();
    setState(() => _projects = list);
  }

  Future<void> _loadGroups() async {
    if (_projectId == null) return;
    final res = await ProjectsRepo.instance.listGroupsByProject(_projectId!);
    setState(() => _groups = res);
  }

  Future<void> _requestJoin() async {
    if (_groupId == null) return;
    setState(() => _loading = true);
    try {
      await ProjectsRepo.instance.requestJoin(_groupId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent')),
      );
      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Request to Join Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _projectId,
              decoration: const InputDecoration(labelText: 'Project'),
              items: _projects.map((p) => DropdownMenuItem(
                value: p['id'] as String,
                child: Text((p['name'] ?? 'Untitled Project') as String),
              )).toList(),
              onChanged: (v) async {
                setState(() {
                  _projectId = v;
                  _groups = [];
                  _groupId = null;
                });
                await _loadGroups();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _groupId,
              decoration: const InputDecoration(labelText: 'Group'),
              items: _groups.map((g) => DropdownMenuItem(
                value: g['id'] as String,
                child: Text((g['name'] ?? 'Group') as String),
              )).toList(),
              onChanged: (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _requestJoin,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(_loading ? 'Sending...' : 'Send Request'),
            ),
          ],
        ),
      ),
    );
  }
}
