import 'package:flutter/material.dart';
import '../screens/create_group_screen.dart';
import '../screens/join_group_screen.dart';
import '../screens/submit_proposal_screen.dart';

class StudentActionsSheet extends StatelessWidget {
  const StudentActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: 18 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(),
          const SizedBox(height: 12),
          _title('Projects • Student'),
          const SizedBox(height: 8),
          _grid(context, blue),
        ],
      ),
    );
  }

  Widget _grabber() => Container(
    height: 4, width: 44,
    decoration: BoxDecoration(
      color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999),
    ),
  );

  Widget _title(String t) => Row(
    children: [
      const Icon(Icons.dashboard_outlined, size: 18, color: Colors.black54),
      const SizedBox(width: 8),
      Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    ],
  );

  Widget _grid(BuildContext context, Color blue) {
    Widget tile(IconData i, String label, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(i, color: blue),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        tile(Icons.group_add_outlined, 'Create Group', () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
        }),
        tile(Icons.person_add_alt_1_outlined, 'Request to Join', () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
        }),
        tile(Icons.upload_file_outlined, 'Submit Proposal', () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubmitProposalScreen()));
        }),
      ],
    );
  }
}
