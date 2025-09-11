import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/session_store.dart';

class CoordinatorAssignSupervisorsScreen extends StatefulWidget {
  const CoordinatorAssignSupervisorsScreen({super.key});

  @override
  State<CoordinatorAssignSupervisorsScreen> createState() =>
      _CoordinatorAssignSupervisorsScreenState();
}

class _CoordinatorAssignSupervisorsScreenState
    extends State<CoordinatorAssignSupervisorsScreen> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  String? _cycleId;
  String _title = '';
  String _mode = 'choose'; // choose | random
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 7));
  int _perGroup = 2;
  int _teacherCap = 4;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _loading = true);
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('project_cycles')
          .select('id,title,department,start_at,end_at,status')
          .eq('status', 'active')
          .lte('start_at', nowIso)
          .gte('end_at', nowIso)
          .order('start_at', ascending: false)
          .limit(1);

      if (rows is List && rows.isNotEmpty) {
        final r = rows.first as Map<String, dynamic>;
        _cycleId = r['id'] as String?;
        _title = (r['title'] ?? '').toString();
      }

      if (_cycleId != null) {
        final s = await _client
            .from('supervisor_settings')
            .select()
            .eq('cycle_id', _cycleId!)
            .maybeSingle();
        if (s != null) {
          _mode = (s['mode'] ?? 'choose').toString();
          final sa = (s['start_at'] as String?) ?? DateTime.now().toUtc().toIso8601String();
          final ea = (s['end_at'] as String?) ?? DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
          _start = DateTime.parse(sa).toLocal();
          _end = DateTime.parse(ea).toLocal();
          _perGroup = s['per_group'] as int? ?? 2;
          _teacherCap = s['teacher_capacity'] as int? ?? 4;
        }
      }
    } catch (_) {
      // keep defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate(bool start) async {
    final init = start ? _start : _end;
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (t == null) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      if (start) {
        _start = dt;
      } else {
        _end = dt;
      }
    });
  }

  Future<void> _save() async {
    if (_cycleId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No active cycle found')));
      return;
    }
    try {
      final email = await SessionStore.getEmail();
      if (email == null || email.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No session email found')));
        return;
      }

      await _client.rpc('set_supervisor_settings', params: {
        'p_cycle_id': _cycleId!,
        'p_mode': _mode,
        'p_start': _start.toUtc().toIso8601String(),
        'p_end': _end.toUtc().toIso8601String(),
        'p_per_group': _perGroup,
        'p_teacher_capacity': _teacherCap,
        'p_email': email, // <-- important
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved settings')));
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _randomAssignNow() async {
    if (_cycleId == null) return;
    try {
      final email = await SessionStore.getEmail();
      if (email == null || email.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No session email found')));
        return;
      }

      await _client.rpc('random_assign_supervisors', params: {
        'p_cycle_id': _cycleId!,
        'p_email': email, // <-- important
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Random assignment done')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    String dtText(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Supervisors')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _infoCard(
                title: _title,
                subtitle:
                'Configure supervisor selection for current cycle'),
            const SizedBox(height: 12),
            const Text('Mode',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'choose', label: Text('Students choose')),
                ButtonSegment(
                    value: 'random', label: Text('Random assign')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) =>
                  setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),
            const Text('Window',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _dateTile(
                      'Start', dtText(_start), () => _pickDate(true)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                  _dateTile('End', dtText(_end), () => _pickDate(false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _numField('Supervisors per group', _perGroup,
                          (v) {
                        final x = int.tryParse(v) ?? _perGroup;
                        setState(() => _perGroup = x.clamp(1, 3));
                      }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numField(
                      'Max groups per teacher', _teacherCap, (v) {
                    final x = int.tryParse(v) ?? _teacherCap;
                    setState(() => _teacherCap = x.clamp(1, 20));
                  }),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save settings'),
            ),
            const SizedBox(height: 12),
            if (_mode == 'random')
              OutlinedButton.icon(
                onPressed: _randomAssignNow,
                icon: const Icon(Icons.auto_mode_outlined),
                label: const Text('Randomly assign now'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.event_available_outlined)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$title\n$subtitle',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String label, String value, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _numField(
      String label, int value, ValueChanged<String> onChanged) {
    return TextField(
      controller: TextEditingController(text: value.toString()),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}
