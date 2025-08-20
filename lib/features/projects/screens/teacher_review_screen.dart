import 'package:flutter/material.dart';
import '../repo/supabase_projects_repo.dart';

class TeacherReviewScreen extends StatefulWidget {
  const TeacherReviewScreen({super.key});

  @override
  State<TeacherReviewScreen> createState() => _TeacherReviewScreenState();
}

class _TeacherReviewScreenState extends State<TeacherReviewScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _pendingGroups = [];
  List<Map<String, dynamic>> _joinRequests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ProjectsRepo.instance;
    final g = await repo.teacherPendingGroups();
    final r = await repo.teacherPendingJoinRequests();
    setState(() {
      _pendingGroups = g;
      _joinRequests = r;
      _loading = false;
    });
  }

  Future<void> _decideGroup(String id, bool approve) async {
    await ProjectsRepo.instance.teacherApproveGroup(groupId: id, approve: approve);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Group approved' : 'Group rejected')),
    );
  }

  Future<void> _decideJoin(String requestId, bool approve) async {
    await ProjectsRepo.instance.approveJoinRequest(requestId: requestId, approve: approve);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Join approved' : 'Join rejected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher • Review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Pending Groups', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_pendingGroups.isEmpty)
              const Text('No pending groups.'),
            ..._pendingGroups.map((g) => Card(
              child: ListTile(
                title: Text(g['name'] ?? 'Group'),
                subtitle: Text('Project: ${g['project_name'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _decideGroup(g['id'] as String, false)),
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _decideGroup(g['id'] as String, true)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
            const Text('Join Requests', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_joinRequests.isEmpty)
              const Text('No join requests.'),
            ..._joinRequests.map((r) => Card(
              child: ListTile(
                title: Text('Requester: ${r['requester_name'] ?? r['requester_id']}'),
                subtitle: Text('Group: ${r['group_name']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _decideJoin(r['id'] as String, false)),
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _decideJoin(r['id'] as String, true)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
