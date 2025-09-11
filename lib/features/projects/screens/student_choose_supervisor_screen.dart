import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectedu/utils/session_store.dart';

class StudentChooseSupervisorScreen extends StatefulWidget {
  const StudentChooseSupervisorScreen({super.key});

  @override
  State<StudentChooseSupervisorScreen> createState() => _StudentChooseSupervisorScreenState();
}

class _StudentChooseSupervisorScreenState extends State<StudentChooseSupervisorScreen> {
  final _client = Supabase.instance.client;
  bool _loading = true;

  String? _cycleId;
  String _cycleTitle = '';
  String _mode = 'choose';
  int _perGroup = 2;

  String _myEmail = '';
  String? _myGroupId;
  String? _myGroupNo;
  String? _department;

  final _domainC = TextEditingController();
  final Set<String> _selectedTeachers = {};

  List<Map<String,dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() { _domainC.dispose(); super.dispose(); }

  Future<void> _boot() async {
    setState(() => _loading = true);
    try {
      final cur = await SessionStore.current();
      _myEmail = cur.email;

      // active cycle
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final cycRows = await _client
          .from('project_cycles')
          .select('id,title,department')
          .eq('status','active')
          .lte('start_at', nowIso).gte('end_at', nowIso)
          .order('start_at', ascending: false).limit(1);

      if (cycRows is List && cycRows.isNotEmpty) {
        final r = cycRows.first as Map<String,dynamic>;
        _cycleId = r['id'] as String;
        _cycleTitle = (r['title'] ?? '').toString();
        _department = r['department'] as String?;
      } else {
        throw 'No active cycle.';
      }

      // settings
      final s = await _client
          .from('supervisor_settings')
          .select()
          .eq('cycle_id', _cycleId!).maybeSingle();
      if (s == null) throw 'Coordinator has not enabled supervisor selection.';
      _mode = (s['mode'] ?? 'choose').toString();
      _perGroup = s['per_group'] as int? ?? 2;

      if (_mode != 'choose') throw 'Coordinator enabled "random assign".';

      // my group as leader
      final myG = await _client
          .from('project_group_members')
          .select('group_id, role_in_group, project_groups!inner(group_no, cycle_id)')
          .eq('member_email', _myEmail)
          .eq('role_in_group','leader')
          .eq('project_groups.cycle_id', _cycleId!)
          .maybeSingle();

      if (myG == null) {
        throw 'Only the group leader can choose supervisors.';
      }
      _myGroupId = (myG['group_id'] ?? '').toString();
      _myGroupNo = ((myG['project_groups'] as Map)['group_no']).toString();

      // teachers list
      final tQ = _client.from('directory_people')
          .select('email, full_name, department, phone')
          .eq('role','teacher');
      if ((_department ?? '').isNotEmpty) {
        tQ.eq('department', _department!);
      }
      final t = await tQ.order('full_name');
      _teachers = List<Map<String,dynamic>>.from(t);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      Navigator.maybePop(context);
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get canSend => _selectedTeachers.isNotEmpty && _selectedTeachers.length <= _perGroup;

  Future<void> _send() async {
    if (!canSend) return;
    try {
      await _client.rpc('request_supervisors', params: {
        'p_cycle_id': _cycleId!,
        'p_group_id': _myGroupId!,
        'p_teacher_emails': _selectedTeachers.toList(),
        'p_domain': _domainC.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requests sent')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Supervisor')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          _cycleCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _domainC,
              decoration: const InputDecoration(
                labelText: 'Project Domain (optional)',
                hintText: 'e.g., Computer Vision',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select up to $_perGroup teacher(s)',
                  style: const TextStyle(color: Colors.black54)),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _teachers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = _teachers[i];
                final email = (t['email'] ?? '').toString();
                final name  = (t['full_name'] ?? '').toString();
                final dept  = (t['department'] ?? '').toString();
                final selected = _selectedTeachers.contains(email);

                return ListTile(
                  leading: CircleAvatar(child: Text(name.isEmpty ? '?' : name[0])),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('$email • $dept'),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          if (_selectedTeachers.length < _perGroup) {
                            _selectedTeachers.add(email);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Max $_perGroup teacher(s)')),
                            );
                          }
                        } else {
                          _selectedTeachers.remove(email);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    final now = _selectedTeachers.contains(email);
                    setState(() {
                      if (!now) {
                        if (_selectedTeachers.length < _perGroup) {
                          _selectedTeachers.add(email);
                        }
                      } else {
                        _selectedTeachers.remove(email);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: canSend ? _send : null,
            icon: const Icon(Icons.outgoing_mail),
            label: const Text('Send request(s)'),
          ),
        ),
      ),
    );
  }

  Widget _cycleCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.groups_2_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$_cycleTitle • Group $_myGroupNo',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
