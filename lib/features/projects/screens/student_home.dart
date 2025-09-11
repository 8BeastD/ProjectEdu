import 'package:flutter/material.dart';
import 'package:projectedu/features/projects/widgets/edu_nav_shell.dart';
import 'profile_screen.dart';
import '../screens/student_choose_supervisor_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/join_group_screen.dart';
import '../screens/user_notifications_page.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return EduNavShell(
      role: 'Student',
      pages: const [
        _StudentDashboard(),                 // new mini-dashboard (below)
        _Stub(title: 'Emergency • Student'),
        UserNotificationsPage(),
        ProfileScreen(),
      ],
      labels: const ['Home', 'Emergency', 'Notification', 'Profile'],
      icons: const [
        Icons.home_rounded,
        Icons.emergency_share_outlined,
        Icons.notifications_none_rounded,
        Icons.person_outline_rounded,
      ],
      onFab: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => Padding(
            padding: EdgeInsets.only(
              left: 18, right: 18, top: 14,
              bottom: 18 + MediaQuery.of(context).padding.bottom,
            ),
            child: Wrap(
              runSpacing: 12,
              children: [
                Center(
                  child: Container(height: 4, width: 44,
                      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999))),
                ),
                ListTile(
                  leading: const Icon(Icons.group_add_outlined),
                  title: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen())); },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('Request to Join', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinGroupScreen())); },
                ),
                ListTile(
                  leading: const Icon(Icons.supervisor_account_outlined),
                  title: const Text('Choose Supervisor', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentChooseSupervisorScreen())); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StudentDashboard extends StatelessWidget {
  const _StudentDashboard();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Student Home', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title});
  @override
  Widget build(BuildContext context) => Center(child: Text(title, style: Theme.of(context).textTheme.titleLarge));
}
