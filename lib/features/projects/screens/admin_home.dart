import 'package:flutter/material.dart';

import 'package:projectedu/features/projects/widgets/edu_nav_shell.dart';
import 'profile_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return EduNavShell(
      role: 'Coordinator',
      pages: const [
        _Stub(title: 'Home • Coordinator'),
        _Stub(title: 'Emergency • Coordinator'),
        _Stub(title: 'Notifications • Coordinator'),
        ProfileScreen(), // ✅ real profile
      ],
      labels: const ['Home', 'Emergency', 'Notification', 'Profile'],
      icons: const [
        Icons.home_rounded,
        Icons.health_and_safety_outlined,
        Icons.notifications_none_rounded,
        Icons.person_outline_rounded,
      ],
      onFab: () {
        // Coordinator create action (e.g., global announcement)
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
