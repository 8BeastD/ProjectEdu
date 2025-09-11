import 'package:flutter/material.dart';
import '../screens/coordinator_settings_screen.dart';
import '../screens/coordinator_assign_supervisors_screen.dart';

/// Open this to show the Coordinator actions sheet.
/// Uses root navigator for subsequent screen pushes.
Future<void> showCoordinatorActionsSheet(BuildContext context) {
  final rootContext = context;
  return showModalBottomSheet(
    context: rootContext,
    useSafeArea: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => CoordinatorActionsSheet(rootContext: rootContext, sheetContext: sheetCtx),
  );
}

class CoordinatorActionsSheet extends StatelessWidget {
  final BuildContext rootContext;   // main app navigator
  final BuildContext sheetContext;  // bottom sheet navigator
  const CoordinatorActionsSheet({super.key, required this.rootContext, required this.sheetContext});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);

    Widget smallTile(IconData i, String t, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(sheetContext);     // close sheet FIRST
          Future.microtask(onTap);         // then perform navigation on root
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: blue.withOpacity(.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6EAF3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(i, color: blue, size: 20),
              const SizedBox(height: 6),
              Text(t, textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18, right: 18, top: 14,
          bottom: 18 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4, width: 44,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.settings_suggest_outlined, size: 18, color: Colors.black54),
                SizedBox(width: 8),
                Text('Projects • Coordinator',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.10,
              children: [
                smallTile(Icons.rule_folder_outlined, 'Project Rules', () {
                  Navigator.of(rootContext, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const CoordinatorSettingsScreen()),
                  );
                }),
                smallTile(Icons.event_note_outlined, 'Deadlines', () {
                  Navigator.of(rootContext, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const CoordinatorSettingsScreen()),
                  );
                }),
                smallTile(Icons.supervisor_account_outlined, 'Assign Teachers', () {
                  // **This is the important part**
                  Navigator.of(rootContext, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const CoordinatorAssignSupervisorsScreen()),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
