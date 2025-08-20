import 'package:flutter/material.dart';
import '../repo/supabase_projects_repo.dart';
import 'group_details_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _projectId;
  String _groupName = '';
  bool _loading = false;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final list = await ProjectsRepo.instance.listProjects();
    setState(() => _projects = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _projectId,
                decoration: const InputDecoration(labelText: 'Project'),
                items: _projects.map((p) => DropdownMenuItem(
                  value: p['id'] as String,
                  child: Text(p['name'] as String),
                )).toList(),
                onChanged: (v) => setState(() => _projectId = v),
                validator: (v) => v == null ? 'Select a project' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Group name'),
                onChanged: (v) => _groupName = v.trim(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter group name' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: const Icon(Icons.group_add_outlined),
                label: Text(_loading ? 'Creating...' : 'Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final g = await ProjectsRepo.instance.createGroup(
        projectId: _projectId!,
        groupName: _groupName,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GroupDetailsScreen(groupId: g['id'] as String)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
