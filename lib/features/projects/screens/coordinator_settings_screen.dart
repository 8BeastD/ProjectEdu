import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CoordinatorSettingsScreen extends StatefulWidget {
  const CoordinatorSettingsScreen({super.key});

  @override
  State<CoordinatorSettingsScreen> createState() => _CoordinatorSettingsScreenState();
}

class _CoordinatorSettingsScreenState extends State<CoordinatorSettingsScreen> {
  final _client = Supabase.instance.client;

  final _titleC = TextEditingController(text: 'Minor Project – Cycle 1');
  final _deptC = TextEditingController(text: 'CSE');

  DateTime _start = DateTime.now().add(const Duration(minutes: 5));
  DateTime _end = DateTime.now().add(const Duration(days: 7));
  int _min = 2;
  int _max = 4;
  bool _saving = false;

  @override
  void dispose() {
    _titleC.dispose();
    _deptC.dispose();
    super.dispose();
  }

  Future<void> _pick(bool pickStart) async {
    final base = pickStart ? _start : _end;

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: base,
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (pickedTime == null) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (pickStart) {
        _start = dt;
      } else {
        _end = dt;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    if (_min < 1 || _max < _min) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check group size: Min must be ≥ 1 and ≤ Max.')),
      );
      return;
    }
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final email = _client.auth.currentUser?.email ?? 'coordinator@kiit.ac.in';

      final inserting = {
        'title': _titleC.text.trim(),
        'start_at': _start.toUtc().toIso8601String(),
        'end_at': _end.toUtc().toIso8601String(),
        'min_group_size': _min,
        'max_group_size': _max,
        'department': _deptC.text.trim().isEmpty ? null : _deptC.text.trim(),
        'created_by': email,
        'status': 'active',
      };

      final row = await _client
          .from('project_cycles')
          .insert(inserting)
          .select('id,title')
          .single();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cycle created: ${row['title']}')),
      );
      // Return the new cycle id to previous screen (optional)
      Navigator.pop(context, row['id']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create cycle: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy, HH:mm');
    const blue = Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Cycle Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleC,
            decoration: const InputDecoration(
              labelText: 'Cycle Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deptC,
            decoration: const InputDecoration(
              labelText: 'Department (optional, e.g. CSE)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Start / End pickers
          Row(
            children: [
              Expanded(
                child: _PickTile(
                  label: 'Start',
                  value: df.format(_start),
                  onTap: () => _pick(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickTile(
                  label: 'End',
                  value: df.format(_end),
                  onTap: () => _pick(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Min / Max
          Row(
            children: [
              Expanded(
                child: _NumField(
                  label: 'Min Group Size',
                  value: _min,
                  onChanged: (v) => setState(() => _min = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumField(
                  label: 'Max Group Size',
                  value: _max,
                  onChanged: (v) => setState(() => _max = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Save button
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.rocket_launch_outlined),
            label: Text(_saving ? 'Starting…' : 'Start Cycle & Notify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'A notification for teachers is created automatically by a DB trigger.\n'
                'You can later attach a PDF by setting pdf_url on that notification row.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _NumField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    // Keep cursor at end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (s) {
        final v = int.tryParse(s);
        if (v != null) onChanged(v);
      },
    );
  }
}
