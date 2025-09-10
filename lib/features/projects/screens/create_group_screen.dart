import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectedu/utils/session_store.dart';

class CreateGroupScreen extends StatefulWidget {
  final String? cycleId; // If null, picks current active cycle automatically
  const CreateGroupScreen({super.key, this.cycleId});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _client = Supabase.instance.client;

  final _searchC = TextEditingController();
  bool _loading = true;
  bool _submitting = false;

  // cycle
  String? _resolvedCycleId;
  String _cycleTitle = '';
  int _minSize = 2;
  int _maxSize = 4;
  String? _department;

  // data
  List<_Student> _all = [];
  List<_Student> _filtered = [];
  final Set<String> _selectedEmails = {};

  // signed-in student (fixed leader)
  String? _fixedLeaderEmail;

  String? _fatalMsg;
  DateTime? _lastMaxToastAt;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _searchC.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // 1) Who is logged in? (from our local SessionStore)
      _fixedLeaderEmail = (await SessionStore.getEmail())?.trim().toLowerCase();

      // 2) Which cycle to use?
      _resolvedCycleId = widget.cycleId;
      if (_resolvedCycleId == null) {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        final rows = await _client
            .from('project_cycles')
            .select('id,title,start_at,end_at,min_group_size,max_group_size,department,status')
            .eq('status', 'active')
            .lte('start_at', nowIso)
            .gte('end_at', nowIso)
            .order('start_at', ascending: false)
            .limit(1);

        if (rows is List && rows.isNotEmpty) {
          final r = rows.first as Map<String, dynamic>;
          _resolvedCycleId = '${r['id']}';
          _cycleTitle = '${r['title']}';
          _minSize = (r['min_group_size'] ?? 2) as int;
          _maxSize = (r['max_group_size'] ?? 4) as int;
          _department = r['department'] as String?;
        } else {
          _fatalMsg = 'No active project cycle found.\nAsk the coordinator to start one.';
          setState(() => _loading = false);
          return;
        }
      } else {
        final cycle = await _client
            .from('project_cycles')
            .select('id,title,start_at,end_at,min_group_size,max_group_size,department,status')
            .eq('id', widget.cycleId!)
            .maybeSingle();
        if (cycle == null) {
          _fatalMsg = 'Cycle not found.';
          setState(() => _loading = false);
          return;
        }
        _cycleTitle = '${cycle['title']}';
        _minSize = (cycle['min_group_size'] ?? 2) as int;
        _maxSize = (cycle['max_group_size'] ?? 4) as int;
        _department = cycle['department'] as String?;
      }

      // 3) Load students (view backed by directory_people)
      final q = _client
          .from('v_students')
          .select('email, full_name, university_id, department, phone, hostel');
      if ((_department ?? '').trim().isNotEmpty) {
        q.eq('department', _department!);
      }
      final rows = await q.order('full_name', ascending: true);

      _all = (rows as List)
          .map((r) => _Student(
        email: '${(r as Map)['email']}',
        name: '${r['full_name']}',
        roll: '${r['university_id']}',
        dept: '${r['department']}',
        phone: '${r['phone']}',
        hostel: '${r['hostel']}',
      ))
          .toList();

      // 3a) If leader got filtered out by dept, fetch & inject at top so they’re visible.
      if (_fixedLeaderEmail != null &&
          !_all.any((s) => s.email.toLowerCase() == _fixedLeaderEmail)) {
        final me = await _client
            .from('v_students')
            .select('email, full_name, university_id, department, phone, hostel')
            .eq('email', _fixedLeaderEmail!)
            .maybeSingle();
        if (me != null) {
          final m = me as Map<String, dynamic>;
          _all.insert(
            0,
            _Student(
              email: '${m['email']}',
              name: '${m['full_name']}',
              roll: '${m['university_id']}',
              dept: '${m['department']}',
              phone: '${m['phone']}',
              hostel: '${m['hostel']}',
            ),
          );
        }
      }

      // 4) Auto-select & lock the leader
      if (_fixedLeaderEmail != null &&
          _all.any((s) => s.email.toLowerCase() == _fixedLeaderEmail)) {
        _selectedEmails.add(_fixedLeaderEmail!);
      }

      _filtered = List.from(_all);
    } on PostgrestException catch (e) {
      _fatalMsg = 'Failed to load students (RLS?): ${e.message}';
    } catch (e) {
      _fatalMsg = 'Failed to load: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchC.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_all);
      } else {
        _filtered = _all.where((s) {
          return s.name.toLowerCase().contains(q) ||
              s.roll.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q) ||
              s.dept.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  bool get _sizeOk => _selectedEmails.length >= _minSize && _selectedEmails.length <= _maxSize;

  void _showMaxToastOnce() {
    final now = DateTime.now();
    if (_lastMaxToastAt != null && now.difference(_lastMaxToastAt!) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastMaxToastAt = now;
    final m = ScaffoldMessenger.maybeOf(context);
    m?.clearSnackBars();
    m?.showSnackBar(
      SnackBar(
        content: Text('Max $_maxSize members allowed'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_sizeOk || _submitting) return;

    if (_resolvedCycleId == null || _resolvedCycleId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active cycle id.')),
      );
      return;
    }

    // Leader must be the signed-in student (fixed)
    final leader = _fixedLeaderEmail;
    if (leader == null || leader.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in as a student to create a group.')),
      );
      return;
    }
    if (!_selectedEmails.contains(leader)) {
      _selectedEmails.add(leader); // safety
    }

    setState(() => _submitting = true);
    try {
      final members = _selectedEmails.toList();

      final res = await _client.rpc('create_project_group', params: {
        'p_cycle_id': _resolvedCycleId!,
        'p_leader_email': leader,
        'p_member_emails': members,
      });

      if (res is! List || res.isEmpty) {
        throw 'RPC returned empty';
      }
      final row = (res.first as Map<String, dynamic>);
      final groupNo = row['group_no'];
      final groupCode = row['group_code'];

      if (!mounted) return;
      // Wait for user to acknowledge success
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Group Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Group #: $groupNo', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SelectableText(
                'Group Code: $groupCode',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 10),
              const Text('Share this code with your teammates.'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );

      if (!mounted) return;
      // Pop back to the previous screen (the one that opened CreateGroupScreen)
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create group: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);

    final createBtnStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((s) {
        if (s.contains(MaterialState.disabled)) {
          return Theme.of(context).colorScheme.surfaceVariant;
        }
        return blue;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((s) {
        if (s.contains(MaterialState.disabled)) {
          return Theme.of(context).colorScheme.onSurfaceVariant;
        }
        return Colors.white; // white text when enabled (blue bg)
      }),
      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 14)),
      shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _fatalMsg != null
          ? _FatalMessage(msg: _fatalMsg!)
          : Column(
        children: [
          _CycleBanner(title: _cycleTitle, minSize: _minSize, maxSize: _maxSize, dept: _department),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Search by name, roll, email, or department…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Tag(label: 'Selected: ${_selectedEmails.length}/$_maxSize', bold: true),
                        const SizedBox(width: 8),
                        if (!_sizeOk) const _Tag(label: 'Select within allowed size', danger: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Source: directory',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black45, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6EAF3)),
              ),
              child: _filtered.isEmpty
                  ? const Center(
                child: Text(
                  'No students found.\nCheck data and RLS policies on table "directory".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                ),
              )
                  : Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 900),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Select')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Roll No.')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Hostel')),
                        ],
                        rows: _filtered.map((s) {
                          final selected = _selectedEmails.contains(s.email);
                          final isFixedLeader =
                          (_fixedLeaderEmail != null && s.email.toLowerCase() == _fixedLeaderEmail);
                          return DataRow(
                            selected: selected,
                            onSelectChanged: (_) {
                              setState(() {
                                if (!selected) {
                                  if (_selectedEmails.length < _maxSize) {
                                    _selectedEmails.add(s.email);
                                  } else {
                                    _showMaxToastOnce();
                                  }
                                } else {
                                  if (!isFixedLeader) _selectedEmails.remove(s.email);
                                }
                              });
                            },
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: selected,
                                  onChanged: isFixedLeader
                                      ? null
                                      : (v) {
                                    setState(() {
                                      if (v == true) {
                                        if (_selectedEmails.length < _maxSize) {
                                          _selectedEmails.add(s.email);
                                        } else {
                                          _showMaxToastOnce();
                                        }
                                      } else {
                                        _selectedEmails.remove(s.email);
                                      }
                                    });
                                  },
                                ),
                              ),
                              DataCell(Row(
                                children: [
                                  if (isFixedLeader)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(Icons.star, size: 16, color: Colors.amber),
                                    ),
                                  Flexible(child: Text(s.name)),
                                ],
                              )),
                              DataCell(Text(s.roll)),
                              DataCell(Text(s.dept)),
                              DataCell(Text(s.email)),
                              DataCell(Text(s.phone)),
                              DataCell(Text(s.hostel)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _fatalMsg != null
          ? null
          : Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.group_add_outlined),
                  label: Text(_submitting ? 'Creating…' : 'Create Group'),
                  onPressed: _sizeOk && !_submitting ? _submit : null,
                  style: createBtnStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Student {
  final String email;
  final String name;
  final String roll;
  final String dept;
  final String phone;
  final String hostel;
  _Student({
    required this.email,
    required this.name,
    required this.roll,
    required this.dept,
    required this.phone,
    required this.hostel,
  });
}

class _CycleBanner extends StatelessWidget {
  final String title;
  final int minSize;
  final int maxSize;
  final String? dept;
  const _CycleBanner({required this.title, required this.minSize, required this.maxSize, this.dept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF2563EB).withOpacity(0.10),
          const Color(0xFF7C3AED).withOpacity(0.06),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.groups_2_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title\nGroup size: $minSize–$maxSize${dept == null ? '' : ' • $dept'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool bold;
  final bool danger;
  const _Tag({required this.label, this.bold = false, this.danger = false});
  @override
  Widget build(BuildContext context) {
    final c = danger ? const Color(0xFFE11D48) : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: danger ? const Color(0xFFE11D48) : const Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _FatalMessage extends StatelessWidget {
  final String msg;
  const _FatalMessage({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}
