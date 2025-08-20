import 'package:flutter/material.dart';
import 'package:projectedu/features/projects/widgets/edu_nav_shell.dart';
import 'profile_screen.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return EduNavShell(
      role: 'Student',
      pages: const [
        _Stub(title: 'Home • Student'),
        _Stub(title: 'Emergency • Student'),
        _Stub(title: 'Notifications • Student'),
        ProfileScreen(), // ✅ real profile
      ],
      labels: const ['Home', 'Emergency', 'Notification', 'Profile'],
      icons: const [
        Icons.home_rounded,
        Icons.emergency_share_outlined,
        Icons.notifications_none_rounded,
        Icons.person_outline_rounded,
      ],
      onFab: () {
        // Student create action
      },
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
