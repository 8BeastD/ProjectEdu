import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:projectedu/supabase_config.dart';
import 'package:projectedu/utils/session_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _row;
  bool _loading = true;
  String _email = '';
  String _role = 'student';

  // Student: members of my group
  List<Map<String, dynamic>> _groupMembers = [];

  // Teacher: groups under my department -> members map
  List<_GroupData> _teacherGroups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final saved = await SessionStore.current();
    _email = (saved.email).trim().toLowerCase();
    _role = saved.role; // 'student' | 'teacher' | 'admin'

    if (_email.isEmpty) {
      setState(() => _loading = false);
      _toast('No session email found. Please log in again.', true);
      return;
    }

    try {
      final client = SupabaseInit.client;

      final r = await client
          .from('directory_people')
          .select(
          'email, full_name, university_id, role, phone, department, hostel, group_no, avatar_url')
          .eq('email', _email)
          .maybeSingle();

      _row = r;

      // Load group data based on role
      if (r != null && r['role'] == 'student') {
        final grp = r['group_no'];
        if (grp != null) {
          final members = await client
              .from('directory_people')
              .select('email, full_name, phone, group_no, avatar_url')
              .eq('group_no', grp);
          _groupMembers = List<Map<String, dynamic>>.from(members);
        } else {
          _groupMembers = [];
        }
      } else if (r != null && r['role'] == 'teacher') {
        final dept = r['department'];
        // Fetch everyone in my department having a non-null group_no
        final all = await client
            .from('directory_people')
            .select('email, full_name, phone, group_no, avatar_url')
            .eq('department', dept)
            .not('group_no', 'is', null);

        final list = List<Map<String, dynamic>>.from(all);
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final m in list) {
          final g = (m['group_no'] ?? '').toString();
          if (g.isEmpty) continue;
          grouped.putIfAbsent(g, () => []).add(m);
        }
        _teacherGroups = grouped.entries
            .map((e) => _GroupData(groupNo: e.key, members: e.value))
            .toList()
          ..sort((a, b) => a.groupNo.compareTo(b.groupNo));
      }

      setState(() => _loading = false);
      if (r == null) _toast('No profile found for $_email', true);
    } catch (e) {
      setState(() => _loading = false);
      _toast('Failed to load profile: $e', true);
    }
  }

  Future<void> _signOut() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _toast(String msg, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF2563EB);
    const brandLight = Color(0xFF3B82F6);

    final hasGroupTab = _row != null && _row!['role'] != 'admin';
    final groupTabLabel =
    _row?['role'] == 'teacher' ? 'My Groups' : 'My Group';

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_row == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No profile found'),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // With/without tab layout
    if (!hasGroupTab) {
      // Admin (Coordinator) → Only My Profile
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildHeader(brand, brandLight),
            const SizedBox(height: 12),
            Expanded(child: _buildProfileList()),
          ],
        ),
      );
    }

    // Student/Teacher → Tabs (My Profile / My Group[s])
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: _buildAppBar(),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildHeader(brand, brandLight),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6EAF3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: TabBar(
                indicatorColor: brand,
                labelColor: brand,
                unselectedLabelColor: Colors.black87,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, letterSpacing: .2),
                tabs: [
                  const Tab(text: 'My Profile'),
                  Tab(text: groupTabLabel),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProfileList(),
                  _row!['role'] == 'teacher'
                      ? _buildTeacherGroups()
                      : _buildStudentGroup(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      title: const Text('Profile'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
        )
      ],
    );
  }

  Widget _buildHeader(Color brand, Color brandLight) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brand, brandLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: _avatarBox(_row?['avatar_url'], 44),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_row!['full_name'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _RolePill(text: _roleLabel(_row!['role'])),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _email.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .moveY(begin: 10, end: 0);
  }

  // ============ TAB: My Profile ============
  Widget _buildProfileList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Section(
            title: 'Basic Information',
            children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Name',
                value: (_row!['full_name'] ?? '').toString(),
              ),
              _InfoRow(
                icon: Icons.verified_user_outlined,
                label: 'Category',
                value: _roleLabel(_row!['role']),
              ),
              _InfoRow(
                icon: Icons.call_outlined,
                label: 'Contact Number',
                value: (_row!['phone'] ?? 'N/A').toString(),
              ),
              _InfoRow(
                icon: Icons.mail_outline,
                label: 'Email',
                value: _email,
              ),
              if ((_row!['university_id'] ?? '').toString().isNotEmpty)
                _InfoRow(
                  icon: Icons.numbers_rounded,
                  label: 'University ID',
                  value: (_row!['university_id'] ?? '').toString(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Institute Details',
            children: [
              _InfoRow(
                icon: Icons.school_outlined,
                label: 'Department',
                value: (_row!['department'] ?? 'N/A').toString(),
              ),
              _InfoRow(
                icon: Icons.location_city_outlined,
                label: 'Hostel / Block',
                value: (_row!['hostel'] ?? 'N/A').toString(),
              ),
            ],
          ),
          const SizedBox(height: 26),
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.power_settings_new_rounded),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ TAB: My Group (Student) ============
  Widget _buildStudentGroup() {
    if ((_row?['group_no']) == null) {
      return _groupEmptyCard(
        title: 'My Group',
        subtitle:
        'You’re not in a group yet.\nOnce your group is assigned, members will appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _GroupMembersCard(
          title: 'Group Members',
          members: _groupMembers,
          onTapMember: (m) => _showMemberDialog(m),
        ),
        const SizedBox(height: 8),
        const _InfoHint(),
      ],
    );
  }

  // ============ TAB: My Groups (Teacher) ============
  Widget _buildTeacherGroups() {
    if (_teacherGroups.isEmpty) {
      return _groupEmptyCard(
        title: 'My Groups',
        subtitle:
        'No groups found under your department yet.\nThey will appear here once created.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        for (final g in _teacherGroups)
          _TeacherGroupTile(
            groupNo: g.groupNo,
            count: g.members.length,
            onOpen: () => _openGroupSheet(g),
          ),
        const SizedBox(height: 8),
        const _InfoHint(),
      ],
    );
  }

  // ======= UI Helpers =======

  Widget _avatarBox(String? url, double iconSize) {
    if (url != null && url.toString().trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(url, fit: BoxFit.cover),
      );
    }
    return const Icon(Icons.person, size: 44, color: Color(0xFF2563EB));
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'teacher':
        return 'Supervisor';
      case 'admin':
        return 'Coordinator';
      default:
        return 'Student';
    }
  }

  void _showMemberDialog(Map<String, dynamic> m) {
    final name = (m['full_name'] ?? '').toString();
    final phone = (m['phone'] ?? 'N/A').toString();
    final grp = (m['group_no'] ?? 'N/A').toString();
    final avatarUrl = m['avatar_url'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding:
        const EdgeInsets.only(left: 22, right: 22, top: 22, bottom: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
              (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _kvLine('Name', name, bold: true),
            const SizedBox(height: 10),
            _kvLine('Grp', grp),
            const SizedBox(height: 10),
            _kvLine('Contact Number', phone),
            const SizedBox(height: 6),
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 8, bottom: 6),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  void _openGroupSheet(_GroupData g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
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
                Text(
                  'Group ${g.groupNo}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text('${g.members.length} members',
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 14),
                _AvatarGrid(
                  members: g.members,
                  onTapMember: (m) => _showMemberDialog(m),
                ),
                const SizedBox(height: 8),
                const _InfoHint(),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kvLine(String k, String v, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$k - ',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        Expanded(child: Text(v)),
      ],
    );
  }

  Widget _groupEmptyCard({required String title, required String subtitle}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _Section(
          title: title,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.group_outlined,
                        color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(subtitle)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        const _InfoHint(),
      ],
    );
  }
}

// ---------- Reusable Widgets ----------

class _RolePill extends StatelessWidget {
  final String text;
  const _RolePill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
      dense: true,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final void Function(Map<String, dynamic>) onTapMember;
  const _AvatarGrid({required this.members, required this.onTapMember});

  @override
  Widget build(BuildContext context) {
    final cols = MediaQuery.of(context).size.width ~/ 110; // ~100–120px card
    final crossAxisCount = cols.clamp(2, 4);

    return GridView.builder(
      itemCount: members.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 120,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final m = members[i];
        final name = (m['full_name'] ?? '').toString();
        final avatarUrl = m['avatar_url'];
        return GestureDetector(
          onTap: () => onTapMember(m),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage:
                (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                name.split(' ').first.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupMembersCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> members;
  final void Function(Map<String, dynamic>) onTapMember;

  const _GroupMembersCard({
    required this.title,
    required this.members,
    required this.onTapMember,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          child: _AvatarGrid(members: members, onTapMember: onTapMember),
        ),
      ],
    );
  }
}

class _InfoHint extends StatelessWidget {
  const _InfoHint();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Text(
        '*For details, click on above images',
        textAlign: TextAlign.left,
        style: TextStyle(color: Colors.black.withOpacity(.6)),
      ),
    );
  }
}

class _TeacherGroupTile extends StatelessWidget {
  final String groupNo;
  final int count;
  final VoidCallback onOpen;
  const _TeacherGroupTile({
    required this.groupNo,
    required this.count,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Group $groupNo',
      children: [
        ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_2_rounded, color: Color(0xFF2563EB)),
          ),
          title: Text('Group $groupNo',
              style:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: Text('$count members'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onOpen,
        ),
      ],
    );
  }
}

// Simple data holder for teacher groups
class _GroupData {
  final String groupNo;
  final List<Map<String, dynamic>> members;
  _GroupData({required this.groupNo, required this.members});
}
