import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectedu/utils/session_store.dart';

class TeacherRequestsScreen extends StatefulWidget {
  const TeacherRequestsScreen({super.key});

  @override
  State<TeacherRequestsScreen> createState() => _TeacherRequestsScreenState();
}

class _TeacherRequestsScreenState extends State<TeacherRequestsScreen> {
  final _client = Supabase.instance.client;
  String _email = '';
  bool _loading = true;

  int _capacity = 4;
  int _currentLoad = 0;

  List<Map<String,dynamic>> _pending = [];
  List<Map<String,dynamic>> _assigned = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cur = await SessionStore.current();
    _email = cur.email;

    try {
      // find latest active cycle
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final cyc = await _client
          .from('project_cycles')
          .select('id,title')
          .eq('status','active')
          .lte('start_at', nowIso).gte('end_at', nowIso)
          .order('start_at', ascending: false).limit(1);
      if (cyc is! List || cyc.isEmpty) throw 'No active cycle.';
      final cycleId = (cyc.first as Map)['id'] as String;

      final s = await _client.from('supervisor_settings').select().eq('cycle_id', cycleId).maybeSingle();
      if (s != null) _capacity = s['teacher_capacity'] as int? ?? 4;

      final loadQ = await _client
          .from('v_teacher_load')
          .select('groups_count')
          .eq('cycle_id', cycleId)
          .eq('teacher_email', _email)
          .maybeSingle();
      _currentLoad = loadQ == null ? 0 : (loadQ['groups_count'] as int? ?? 0);

      final pend = await _client
          .from('supervisor_requests')
          .select('id, group_no, domain, created_at')
          .eq('teacher_email', _email)
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      _pending = List<Map<String,dynamic>>.from(pend);

      final assn = await _client
          .from('supervisor_assignments')
          .select('group_no, domain, created_at')
          .eq('teacher_email', _email)
          .order('created_at', ascending: true);
      _assigned = List<Map<String,dynamic>>.from(assn);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(String id, bool approve) async {
    try {
      await _client.rpc('teacher_decide_request', params: {
        'p_request_id': id,
        'p_decision': approve ? 'approve' : 'reject',
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final capText = '$_currentLoad / $_capacity';

    return Scaffold(
      appBar: AppBar(title: const Text('Supervisor Dashboard')),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _capacityCard(capText),
            const SizedBox(height: 14),
            Text('Pending Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            if (_pending.isEmpty)
              _empty('No pending requests')
            else
              ..._pending.map((r) => _requestTile(r)).toList(),
            const SizedBox(height: 16),
            Text('My Groups', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            if (_assigned.isEmpty)
              _empty('No assignments yet')
            else
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _assigned.map((a) => _groupChip(a)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _capacityCard(String capText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.assignment_turned_in_outlined)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Capacity', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(capText, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _empty(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(child: Text(t, style: const TextStyle(color: Colors.black54))),
  );

  Widget _groupChip(Map<String,dynamic> a) {
    final no = (a['group_no'] ?? '').toString();
    return Chip(
      label: Text('Group $no'),
      avatar: const CircleAvatar(child: Icon(Icons.groups_2_rounded, size: 18)),
      backgroundColor: const Color(0xFFEFF3FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _requestTile(Map<String,dynamic> r) {
    final id  = r['id'] as String;
    final no  = (r['group_no'] ?? '').toString();
    final dom = (r['domain'] ?? 'N/A').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: ListTile(
        leading: CircleAvatar(child: Text(no)),
        title: Text('Group $no', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Domain: $dom'),
        trailing: Wrap(
          children: [
            TextButton(onPressed: () => _decide(id, false), child: const Text('Reject')),
            const SizedBox(width: 4),
            ElevatedButton(onPressed: () => _decide(id, true), child: const Text('Approve')),
          ],
        ),
      ),
    );
  }
}
