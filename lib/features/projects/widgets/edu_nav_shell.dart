import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ===============================================================
/// Premium Bottom Navigation Shell + Role Sheets (Richer Version)
/// - EduNavShell (unchanged API)
/// - StudentActionsSheet / TeacherActionsSheet / CoordinatorActionsSheet
/// - Premium styling: glass cards, gradients, subtle motion
/// - Ready to wire: uses Navigator.pushNamed for routes (see comments)
/// ===============================================================

class EduNavShell extends StatefulWidget {
  final String role; // "student" | "teacher" | "admin" (admin == coordinator)
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
    const bg = Color(0xFFF7F9FC);
    const blue = Color(0xFF2563EB);

    return Scaffold(
      extendBody: true,
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

    void _openRoleSheet() {
      final role = widget.role.toLowerCase().trim();
      Feedback.forTap(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          if (role == 'student') return const StudentActionsSheet();
          if (role == 'teacher') return const TeacherActionsSheet();
          if (role == 'admin' || role == 'coordinator') {
            return const CoordinatorActionsSheet();
          }
          return const _RoleNotRecognizedSheet();
        },
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? 2 : 0),
      child: SizedBox(
        height: 64,
        width: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // soft glow
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: blue.withOpacity(0.32),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            FloatingActionButton(
              // Always open our role sheet; call onFab AFTER (if provided)
              onPressed: () {
                try {
                  _openRoleSheet();
                  widget.onFab?.call();
                } catch (e) {
                  final m = ScaffoldMessenger.maybeOf(context);
                  m?.showSnackBar(
                    SnackBar(content: Text('Could not open actions: $e')),
                  );
                }
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

    const baseHeight = 64.0;
    final contentHeight = baseHeight + bottomInset;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 14,
          shape: const AutomaticNotchedShape(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                  const Spacer(),
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
                      height: 26,
                      width: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            blue.withOpacity(0.14),
                            blue.withOpacity(0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).animate().fadeIn(duration: 160.ms),
                  Icon(
                    selected ? selectedIcon : baseIcon,
                    size: 22,
                    color: selected ? blue : const Color(0xFF6B7280),
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
        color: const Color(0xFFE11D48),
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

/// ===================================================================
/// Premium Role Sheets
/// ===================================================================

class StudentActionsSheet extends StatelessWidget {
  const StudentActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return _FrostedContainer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + pad.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Grabber(),
            const SizedBox(height: 10),
            const _Header(
              icon: Icons.school_outlined,
              title: 'Projects • Student',
              subtitle: 'Create, join, and submit — all in one place.',
              gradient: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            const SizedBox(height: 16),
            _QuickGrid(
              tiles: [
                _QuickTileData(
                  icon: Icons.group_add_outlined,
                  label: 'Create Group',
                  onTap: () => _safeRoute(context, '/projects/create-group'),
                ),
                _QuickTileData(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Request to Join',
                  onTap: () => _safeRoute(context, '/projects/join-group'),
                ),
                _QuickTileData(
                  icon: Icons.upload_file_outlined,
                  label: 'Submit Proposal',
                  onTap: () => _safeRoute(context, '/projects/submit-proposal'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Tools',
              items: [
                _ActionItem(
                  icon: Icons.groups_2_outlined,
                  title: 'My Groups',
                  subtitle: 'View members, status & teacher decision',
                  onTap: () => _safeRoute(context, '/projects/my-groups'),
                ),
                _ActionItem(
                  icon: Icons.task_alt_outlined,
                  title: 'Tasks',
                  subtitle: 'Plan sprints & track progress',
                  onTap: () => _safeRoute(context, '/projects/tasks'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherActionsSheet extends StatelessWidget {
  const TeacherActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return _FrostedContainer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + pad.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Grabber(),
            const SizedBox(height: 10),
            const _Header(
              icon: Icons.verified_outlined,
              title: 'Projects • Teacher',
              subtitle: 'Review groups, join requests & proposals.',
              gradient: [Color(0xFF22C55E), Color(0xFF2563EB)],
            ),
            const SizedBox(height: 16),
            _QuickGrid(
              tiles: [
                _QuickTileData(
                  icon: Icons.fact_check_outlined,
                  label: 'Review Groups',
                  onTap: () => _safeRoute(context, '/projects/review-groups'),
                ),
                _QuickTileData(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Join Requests',
                  onTap: () => _safeRoute(context, '/projects/join-requests'),
                ),
                _QuickTileData(
                  icon: Icons.article_outlined,
                  label: 'Proposals',
                  onTap: () => _safeRoute(context, '/projects/review-proposals'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Shortcuts',
              items: [
                _ActionItem(
                  icon: Icons.insights_outlined,
                  title: 'Overview',
                  subtitle: 'Pending, approved, deadlines at a glance',
                  onTap: () => _safeRoute(context, '/projects/teacher-overview'),
                ),
                _ActionItem(
                  icon: Icons.event_note_outlined,
                  title: 'Set Remarks',
                  subtitle: 'Provide feedback & request changes',
                  onTap: () => _safeRoute(context, '/projects/remarks'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CoordinatorActionsSheet extends StatelessWidget {
  const CoordinatorActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return _FrostedContainer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + pad.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Grabber(),
            const SizedBox(height: 10),
            const _Header(
              icon: Icons.settings_suggest_outlined,
              title: 'Projects • Coordinator',
              subtitle: 'Rules, windows & assignment preferences.',
              gradient: [Color(0xFF7C3AED), Color(0xFF2563EB)],
            ),
            const SizedBox(height: 16),
            _QuickGrid(
              tiles: [
                _QuickTileData(
                  icon: Icons.tune_outlined,
                  label: 'Project Rules',
                  onTap: () => _safeRoute(context, '/projects/settings'),
                ),
                _QuickTileData(
                  icon: Icons.calendar_month_outlined,
                  label: 'Deadlines',
                  onTap: () => _safeRoute(context, '/projects/deadlines'),
                ),
                _QuickTileData(
                  icon: Icons.person_search_outlined,
                  label: 'Assign Teachers',
                  onTap: () => _safeRoute(context, '/projects/assign-teachers'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Admin',
              items: [
                _ActionItem(
                  icon: Icons.dataset_outlined,
                  title: 'Projects Catalog',
                  subtitle: 'Create/edit projects, max group size, etc.',
                  onTap: () => _safeRoute(context, '/projects/catalog'),
                ),
                _ActionItem(
                  icon: Icons.security_outlined,
                  title: 'Access & Roles',
                  subtitle: 'Who can create, approve, review',
                  onTap: () => _safeRoute(context, '/projects/roles'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A tiny fallback if role is not one of the expected strings.
class _RoleNotRecognizedSheet extends StatelessWidget {
  const _RoleNotRecognizedSheet();

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + pad.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 8),
          Text('Role not recognized',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          SizedBox(height: 6),
          Text('Set role to "student", "teacher", or "admin/coordinator".'),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// ===================================================================
/// Building blocks
/// ===================================================================

class _FrostedContainer extends StatelessWidget {
  final Widget child;
  const _FrostedContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    // Decorative blurred gradient background
    return Stack(
      children: [
        // gradient backdrop
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF101828).withOpacity(0.28),
                    const Color(0xFF101828).withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // card sheet
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0x1A000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, -8),
              )
            ],
          ),
          child: child,
        ).animate().fadeIn(duration: 220.ms).moveY(begin: 12, end: 0, curve: Curves.easeOut),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [gradient.first.withOpacity(0.10), gradient.last.withOpacity(0.06)],
        ),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradient),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF475467), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTileData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _QuickTileData({required this.icon, required this.label, required this.onTap});
}

class _QuickGrid extends StatelessWidget {
  final List<_QuickTileData> tiles;
  const _QuickGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: tiles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (context, i) {
        final t = tiles[i];
        return _QuickTile(icon: t.icon, label: t.label, onTap: t.onTap)
            .animate()
            .fadeIn(duration: 220.ms, delay: (60 * i).ms)
            .moveY(begin: 6, end: 0, curve: Curves.easeOut);
      },
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2563EB);
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
            Icon(icon, color: blue),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_ActionItem> items;

  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
          ...List.generate(items.length, (i) {
            final it = items[i];
            return it
                .animate()
                .fadeIn(duration: 200.ms, delay: (50 * (i + 1)).ms)
                .moveY(begin: 6, end: 0, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2563EB);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blue.withOpacity(0.08),
                border: Border.all(color: const Color(0xFFE6EAF3)),
              ),
              child: Icon(icon, color: blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }
}

/// Pushes a named route safely:
/// - Closes the bottom sheet if open
/// - Pushes on the root navigator next frame
/// - Shows a snackbar if the route is not registered
void _safeRoute(BuildContext context, String routeName) {
  // Close the sheet (if we are in one)
  Navigator.of(context).maybePop();

  // Push in the next frame on the root navigator
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      Navigator.of(context, rootNavigator: true).pushNamed(routeName);
    } catch (e) {
      final m = ScaffoldMessenger.maybeOf(context);
      m?.showSnackBar(
        SnackBar(
          content: Text('Route "$routeName" not found. Wire it in your router.'),
        ),
      );
    }
  });
}
