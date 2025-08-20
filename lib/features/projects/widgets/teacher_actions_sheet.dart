import 'package:flutter/material.dart';
import '../screens/teacher_review_screen.dart';

class TeacherActionsSheet extends StatelessWidget {
  const TeacherActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    return Padding(
      padding: EdgeInsets.only(
        left: 18, right: 18, top: 14, bottom: 18 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, width: 44, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999),
          )),
          const SizedBox(height: 12),
          Row(children: const [
            Icon(Icons.verified_outlined, size: 18, color: Colors.black54),
            SizedBox(width: 8),
            Text('Projects • Teacher', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          _card(context, blue, Icons.rule_folder_outlined, 'Review groups & join requests'),
        ],
      ),
    );
  }

  Widget _card(BuildContext ctx, Color blue, IconData i, String t) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(ctx);
        Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const TeacherReviewScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: blue.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: Row(
          children: [
            Icon(i, color: blue),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
