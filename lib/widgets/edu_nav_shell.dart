import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Premium bottom navigation shell used by Student/Teacher/Coordinator.
/// - 4 tabs + center-docked FAB with notch.
/// - SafeArea-aware, overflow safe on small screens.
/// - Optional badges and selected icon variants.
/// - initialIndex + onTabChanged for state control.
class EduNavShell extends StatefulWidget {
  final String role; // e.g. "Student"
  final List<Widget> pages; // length 4
  final List<String> labels; // length 4
  final List<IconData> icons; // length 4 (unselected)
  final List<IconData>? selectedIcons; // optional length 4 (selected)
  final List<int?>? badges; // optional length 4, null/0 hides badge
  final VoidCallback? onFab;
  final int initialIndex;
  final ValueChanged<int>? onTabChanged;

  const EduNavShell({
    super.key,
    required this.role,
    required this.pages,
    required this.labels,
    required this.icons,
    this.selectedIcons,
    this.badges,
    this.onFab,
    this.initialIndex = 0,
    this.onTabChanged,
  }) : assert(
  pages.length == 4 &&
      labels.length == 4 &&
      icons.length == 4 &&
      (selectedIcons == null || selectedIcons.length == 4) &&
      (badges == null || badges.length == 4),
  );

  @override
  State<EduNavShell> createState() => _EduNavShellState();
}

class _EduNavShellState extends State<EduNavShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    const bg = Color(0xFFF7F9FC);

    return Scaffold(
      extendBody: true, // render BottomAppBar under FAB notch
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: 280.ms,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: widget.pages[_index],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFab(context, blue),
      bottomNavigationBar: _buildBottomBar(context, blue),
    );
  }

  Widget _buildFab(BuildContext context, Color blue) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      // lift FAB slightly when gesture inset present
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? 2 : 0),
      child: SizedBox(
        height: 60,
        width: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // soft glow
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: blue.withOpacity(0.35),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            FloatingActionButton(
              onPressed: widget.onFab ??
                      () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => const _CreateSheet(),
                    );
                  },
              elevation: 0,
              backgroundColor: blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add, size: 28, color: Colors.white),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildBottomBar(BuildContext context, Color blue) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Base height + whatever safe-area is needed. We put SafeArea OUTSIDE.
    const baseHeight = 64.0;
    final contentHeight = baseHeight + bottomInset;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true, // <-- keep the system nav clear
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 12,
          // No fixed height here; we size the child instead to avoid conflicts.
          shape: const AutomaticNotchedShape(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            StadiumBorder(),
          ),
          notchMargin: 8,
          child: SizedBox(
            height: contentHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _buildNavItem(0, scheme, blue),
                  _buildNavItem(1, scheme, blue),
                  const Spacer(), // notch center
                  _buildNavItem(2, scheme, blue),
                  _buildNavItem(3, scheme, blue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int i, ColorScheme scheme, Color blue) {
    final selected = _index == i;
    final baseIcon = widget.icons[i];
    final selectedIcon =
    widget.selectedIcons != null ? widget.selectedIcons![i] : baseIcon;
    final badgeCount = widget.badges != null ? (widget.badges![i] ?? 0) : 0;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_index == i) return;
          setState(() => _index = i);
          Feedback.forTap(context);
          widget.onTabChanged?.call(i);
        },
        child: Padding(
          // slightly tighter padding = more vertical headroom
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (selected)
                    Container(
                      height: 24,
                      width: 52,
                      decoration: BoxDecoration(
                        color: blue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).animate().fadeIn(duration: 150.ms),
                  Icon(
                    selected ? selectedIcon : baseIcon,
                    size: 22,
                    color: selected ? blue : const Color(0xFF6B7280), // slate-500
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: -14,
                      child: _Badge(count: badgeCount),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaleFactor:
                MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.15),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? blue : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48), // rose-600
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet();

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
          Container(
            height: 4,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _quickAction(blue, Icons.task_alt, 'New Task'),
              const SizedBox(width: 12),
              _quickAction(blue, Icons.campaign_outlined, 'Announcement'),
              const SizedBox(width: 12),
              _quickAction(blue, Icons.file_upload_outlined, 'Upload'),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: blue),
            title: const Text('Recent activity'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _quickAction(Color blue, IconData icon, String label) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: blue),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
