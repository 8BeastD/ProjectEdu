import 'package:flutter/material.dart';
import '../repo/supabase_projects_repo.dart';

class CoordinatorSettingsScreen extends StatefulWidget {
  const CoordinatorSettingsScreen({super.key});

  @override
  State<CoordinatorSettingsScreen> createState() => _CoordinatorSettingsScreenState();
}

class _CoordinatorSettingsScreenState extends State<CoordinatorSettingsScreen> {
  List<Map<String, dynamic>> _projects = [];
  String? _projectId;
  int _maxGroupSize = 4;
  int _maxTeachers = 1;
  bool _allowCross = true;
  final _proposalController = TextEditingController();
  final _finalController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _proposalController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await ProjectsRepo.instance.listProjects();
    setState(() => _projects = list);
  }

  Future<void> _save() async {
    if (_projectId == null) return;
    setState(() => _busy = true);
    try {
      await ProjectsRepo.instance.upsertProjectSettings(
        projectId: _projectId!,
        maxGroupSize: _maxGroupSize,
        maxTeachersPerGroup: _maxTeachers,
        allowCrossGroupRequests: _allowCross,
        deadlines: {
          'proposal_due': _proposalController.text.trim(),
          'final_due': _finalController.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coordinator • Project Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _numField('Max group size', _maxGroupSize, (v) => setState(() => _maxGroupSize = v))),
              const SizedBox(width: 12),
              Expanded(child: _numField('Max teachers/group', _maxTeachers, (v) => setState(() => _maxTeachers = v))),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _allowCross,
              onChanged: (v) => setState(() => _allowCross = v),
              title: const Text('Allow cross‑group join requests'),
            ),
            const Divider(height: 28),
            TextField(
              controller: _proposalController,
              decoration: const InputDecoration(
                labelText: 'Proposal due (YYYY‑MM‑DD)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _finalController,
              decoration: const InputDecoration(
                labelText: 'Final submission due (YYYY‑MM‑DD)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_alt),
              label: Text(_busy ? 'Saving...' : 'Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, int value, void Function(int) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => onChanged(int.tryParse(v) ?? value),
    );
  }
}
