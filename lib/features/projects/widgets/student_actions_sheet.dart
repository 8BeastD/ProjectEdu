import 'package:flutter/material.dart';
import '../screens/create_group_screen.dart';
import '../screens/join_group_screen.dart';
import '../screens/submit_proposal_screen.dart';
import '../screens/student_choose_supervisor_screen.dart';

/// Use this to open the sheet. It guarantees pushes use the root navigator.
Future<void> showStudentActionsSheet(BuildContext context) {
  final rootContext = context;
  return showModalBottomSheet(
    context: rootContext,
    useSafeArea: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StudentActionsSheet(rootContext: rootContext, sheetContext: sheetCtx),
  );
}

class StudentActionsSheet extends StatelessWidget {
  final BuildContext rootContext;   // main app navigator
  final BuildContext sheetContext;  // the sheet’s own context
  const StudentActionsSheet({super.key, required this.rootContext, required this.sheetContext});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);

    Widget item(IconData icon, String label, Widget page) {
      return ListTile(
        dense: true,
        minLeadingWidth: 0,
        leading: Icon(icon, color: blue, size: 20),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        onTap: () {
          Navigator.pop(sheetContext); // close the sheet
          // push on the ROOT navigator (never hits unknown route)
          Future.microtask(() {
            Navigator.of(rootContext, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => page),
            );
          });
        },
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14, right: 14, top: 10,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4, width: 44, margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999)),
            ),
            Row(
              children: const [
                Icon(Icons.dashboard_outlined, size: 18, color: Colors.black54),
                SizedBox(width: 8),
                Text('Projects • Student', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  item(Icons.group_add_outlined, 'Create Group', const CreateGroupScreen()),
                  const Divider(height: 1),
                  item(Icons.person_add_alt_1_outlined, 'Request to Join', const JoinGroupScreen()),
                  const Divider(height: 1),
                  item(Icons.upload_file_outlined, 'Submit Proposal', const SubmitProposalScreen()),
                  const Divider(height: 1),
                  item(Icons.supervisor_account_outlined, 'Choose Supervisor', const StudentChooseSupervisorScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
