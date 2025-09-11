import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart'
    show CountOption, PostgrestException, PostgrestResponse;

class CoordinatorDashboardScreen extends StatefulWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  State<CoordinatorDashboardScreen> createState() =>
      _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState extends State<CoordinatorDashboardScreen> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  String? _fatal;

  // cycle
  String? _cycleId;
  String _cycleTitle = '';
  int _minSize = 2;
  int _maxSize = 4;
  String? _dept;

  // stats
  int _totalStudents = 0;
  int _totalGroups = 0;
  int _groupedStudents = 0; // unique emails in this cycle
  int get _remainingStudents => max(_totalStudents - _groupedStudents, 0);

  // weekly chart (day -> group count)
  final List<_DayCount> _last7 = [];

  // groups chip list: [{group_no, group_id, count}]
  final List<_GroupChip> _groups = [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _fatal = null;
    });

    try {
      // 1) resolve active cycle
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('project_cycles')
          .select(
          'id,title,start_at,end_at,min_group_size,max_group_size,department,status')
          .eq('status', 'active')
          .lte('start_at', nowIso)
          .gte('end_at', nowIso)
          .order('start_at', ascending: false)
          .limit(1);

      if (rows is! List || rows.isEmpty) {
        _fatal =
        'No active project cycle is running.\nCreate one from Coordinator Settings.';
        setState(() => _loading = false);
        return;
      }
      final c = (rows.first as Map<String, dynamic>);
      _cycleId = c['id'] as String;
      _cycleTitle = (c['title'] ?? '').toString();
      _minSize = (c['min_group_size'] as int?) ?? 2;
      _maxSize = (c['max_group_size'] as int?) ?? 4;
      _dept = c['department'] as String?;

      // 2) total students (from v_students, optional department filter)
      // Use the new .count() method; it returns a PostgrestResponse with .count
      var q = _client.from('v_students').select('email');
      if (_dept != null && _dept!.isNotEmpty) {
        q = q.eq('department', _dept!);
      }
      final PostgrestResponse stuResp = await q.count(CountOption.exact);
      _totalStudents = stuResp.count ?? 0;

      // 3) groups under this cycle
      final groupsRows = await _client
          .from('project_groups')
          .select('id, group_no, created_at')
          .eq('cycle_id', _cycleId!)
          .order('group_no', ascending: true);

      final groups = List<Map<String, dynamic>>.from(groupsRows as List);
      _totalGroups = groups.length;

      // 4) grouped students & per-group member counts
      final memRows = await _client
          .from('project_group_members')
          .select('group_id, member_email')
          .eq('cycle_id', _cycleId!);
      final mem = List<Map<String, dynamic>>.from(memRows as List);

      final uniqueEmails = <String>{};
      final groupCounts = <String, int>{}; // group_id -> count
      for (final m in mem) {
        final em = (m['member_email'] ?? '').toString();
        if (em.isNotEmpty) uniqueEmails.add(em);
        final gid = (m['group_id'] ?? '').toString();
        if (gid.isEmpty) continue;
        groupCounts[gid] = (groupCounts[gid] ?? 0) + 1;
      }
      _groupedStudents = uniqueEmails.length;

      _groups
        ..clear()
        ..addAll(groups.map((g) {
          final gid = (g['id'] ?? '').toString();
          final gno = (g['group_no'] ?? '').toString();
          return _GroupChip(
            id: gid,
            label: gno,
            count: groupCounts[gid] ?? 0,
            createdAt: DateTime.tryParse((g['created_at'] ?? '').toString()),
          );
        }));

      // 5) last 7 days histogram (by created_at)
      _last7
        ..clear()
        ..addAll(_histogramLast7(_groups));

      setState(() => _loading = false);
    } on PostgrestException catch (e) {
      setState(() {
        _loading = false;
        _fatal = 'Failed to load: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _fatal = 'Failed to load: $e';
      });
    }
  }

  List<_DayCount> _histogramLast7(List<_GroupChip> gs) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final List<_DayCount> days = List.generate(7, (i) {
      final d = base.subtract(Duration(days: 6 - i));
      return _DayCount(date: d, count: 0);
    });

    for (final g in gs) {
      final d = g.createdAt;
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      for (final slot in days) {
        if (slot.date == day) {
          slot.count += 1;
          break;
        }
      }
    }
    return days;
  }

  Future<void> _notifyLeft() async {
    if (_remainingStudents <= 0) return;
    try {
      await _client.from('notifications').insert({
        'audience': 'student',
        'title': 'Form your project group',
        'message':
        'Reminder: Please create or join a group for "${_cycleTitle}".',
        'pdf_url': null
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification queued for students.')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notify failed: ${e.message}')),
      );
    }
  }

  Future<void> _openGroup(String groupId, String label) async {
    try {
      // get member emails for this group
      final memRows = await _client
          .from('project_group_members')
          .select('member_email')
          .eq('group_id', groupId);
      final emails = (memRows as List)
          .map((r) => (r as Map<String, dynamic>)['member_email'].toString())
          .where((e) => e.isNotEmpty)
          .toList();

      if (emails.isEmpty) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => const _MembersSheet(
              title: 'Group', members: <Map<String, dynamic>>[]),
        );
        return;
      }

      // Build IN (...) string safely for email list
      final inList =
          '(${emails.map((e) => '"${e.replaceAll('"', r'\"').replaceAll("'", "''")}"').join(',')})';

      final rows = await _client
          .from('v_students')
          .select('full_name, university_id, email')
          .filter('email', 'in', inList);

      final members = List<Map<String, dynamic>>.from(rows as List);

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _MembersSheet(title: 'Group $label', members: members),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Load members failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_fatal != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 48),
                const SizedBox(height: 12),
                Text(_fatal!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _boot, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final ringPct =
    _totalStudents == 0 ? 0.0 : (_groupedStudents / _totalStudents);
    final pctLabel =
    (_totalStudents == 0) ? '0%' : '${(ringPct * 100).round()}%';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cycleBanner(),
              const SizedBox(height: 10),
              _statsGrid(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _progressRing(pctLabel, ringPct)),
                  const SizedBox(width: 10),
                  Expanded(child: _weeklyBars()),
                ],
              ),
              const SizedBox(height: 8),
              _notifyCard(),
              const SizedBox(height: 12),
              Text('Groups (${_groups.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _groupsWrap(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cycleBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF2563EB).withOpacity(.1),
          const Color(0xFF7C3AED).withOpacity(.06),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.rule_folder_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dept == null || _dept!.isEmpty
                  ? '$_cycleTitle\nGroup size: $_minSize–$_maxSize'
                  : '$_cycleTitle\nGroup size: $_minSize–$_maxSize • $_dept',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _boot,
            icon: const Icon(Icons.refresh_rounded),
          )
        ],
      ),
    );
  }

  Widget _statsGrid() {
    Widget card(IconData i, String t, String v) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(i, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t,
                      style:
                      const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(v,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      children: [
        card(Icons.people_outline, 'Students', '$_totalStudents'),
        card(Icons.groups_outlined, 'Groups', '$_totalGroups'),
        card(Icons.verified_outlined, 'Grouped', '$_groupedStudents'),
        card(Icons.timelapse_outlined, 'Remaining', '$_remainingStudents'),
      ],
    );
  }

  Widget _progressRing(String label, double pct) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: pct.clamp(0.0, 1.0).toDouble(),
              strokeWidth: 10,
              backgroundColor: const Color(0xFFEFF3FF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              const Text('Grouped', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeklyBars() {
    final maxCount = _last7.fold<int>(0, (m, e) => max(m, e.count));
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Groups / last 7 days',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(builder: (ctx, c) {
              final gap = 6.0;
              final barW = (c.maxWidth - gap * 6) / 7;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < _last7.length; i++) ...[
                    _Bar(
                      width: barW,
                      heightPct:
                      maxCount == 0 ? 0 : _last7[i].count / maxCount,
                      label: _short(_last7[i].date),
                      value: _last7[i].count,
                    ),
                    if (i != _last7.length - 1) SizedBox(width: gap),
                  ]
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _notifyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Notify $_remainingStudents left',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton.icon(
            onPressed: _remainingStudents > 0 ? _notifyLeft : null,
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: const Text('Notify'),
          )
        ],
      ),
    );
  }

  Widget _groupsWrap() {
    if (_groups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: const Text('No groups formed yet.',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _groups
          .map((g) => _GroupChipWidget(
        data: g,
        onTap: () => _openGroup(g.id, g.label),
      ))
          .toList(),
    );
  }

  String _short(DateTime d) {
    const wk = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return wk[d.weekday % 7];
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double heightPct;
  final String label;
  final int value;
  const _Bar({
    required this.width,
    required this.heightPct,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final h = heightPct.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(value.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 2),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: (h * 100), // fixed max bar height
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _GroupChip {
  final String id;
  final String label; // group_no
  final int count;
  final DateTime? createdAt;
  _GroupChip({
    required this.id,
    required this.label,
    required this.count,
    this.createdAt,
  });
}

class _GroupChipWidget extends StatelessWidget {
  final _GroupChip data;
  final VoidCallback onTap;
  const _GroupChipWidget({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                data.label,
                style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text('${data.count} mem',
                style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DayCount {
  final DateTime date;
  int count;
  _DayCount({required this.date, required this.count});
}

class _MembersSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> members;
  const _MembersSheet({required this.title, required this.members});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
        const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 44,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No members in this group yet.',
                    style: TextStyle(color: Colors.black54)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = members[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF3FF),
                      child:
                      Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                    ),
                    title: Text(
                      (m['full_name'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Roll: ${(m['university_id'] ?? '').toString()}'),
                        Text((m['email'] ?? '').toString()),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
