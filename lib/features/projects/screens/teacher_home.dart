import 'package:flutter/material.dart';
import 'package:projectedu/features/projects/widgets/edu_nav_shell.dart';
import 'profile_screen.dart';
import '../screens/teacher_requests_screen.dart';
import '../screens/user_notifications_page.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    return EduNavShell(
      role: 'Supervisor',
      pages: const [
        TeacherRequestsScreen(),            // dashboard/inbox
        _Stub(title: 'Emergency • Supervisor'),
        UserNotificationsPage(),
        ProfileScreen(),
      ],
      labels: const ['Home', 'Emergency', 'Notification', 'Profile'],
      icons: const [
        Icons.home_rounded,
        Icons.emergency_outlined,
        Icons.notifications_none_rounded,
        Icons.person_outline_rounded,
      ],
      onFab: () {},
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title});
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(title, style: Theme.of(context).textTheme.titleLarge));
}
