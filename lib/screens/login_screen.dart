import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';
import 'student_home.dart';
import 'teacher_home.dart';
import 'admin_home.dart';

enum AppRole { student, teacher, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrRoll = TextEditingController();
  bool _isSubmitting = false;

  AppRole _role = AppRole.student;

  @override
  void dispose() {
    _emailOrRoll.dispose();
    super.dispose();
  }

  String _roleString(AppRole r) {
    switch (r) {
      case AppRole.student:
        return 'student';
      case AppRole.teacher:
        return 'teacher';
      case AppRole.admin:
        return 'admin';
    }
  }

  String _normalizeEmail(String input) {
    final raw = input.trim().toLowerCase();
    if (_role == AppRole.student) {
      // Accept either "2230265" or "2230265@kiit.ac.in"
      if (!raw.contains('@')) return '$raw@kiit.ac.in';
      return raw;
    } else {
      // Teacher/Admin must use kiit email
      return raw;
    }
  }

  bool _validateStudentFormat(String input) {
    // Allow just digits, or digits@kiit.ac.in
    final v = input.trim().toLowerCase();
    final rollOnly = RegExp(r'^\d{6,}$'); // 6+ digits
    final rollEmail = RegExp(r'^\d{6,}@kiit\.ac\.in$');
    return rollOnly.hasMatch(v) || rollEmail.hasMatch(v);
  }

  bool _validateStaffFormat(String input) {
    final v = input.trim().toLowerCase();
    return v.endsWith('@kiit.ac.in') && v.contains('@') && !RegExp(r'^\d+@').hasMatch(v);
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final client = SupabaseInit.client;
    try {
      final email = _normalizeEmail(_emailOrRoll.text);
      final role = _roleString(_role);

      // ✅ FIX: no type arg on select()
      final row = await client
          .from('directory_people')
          .select()
          .eq('email', email)
          .eq('role', role)
          .maybeSingle();

      if (row == null) {
        _snack('No account found for this ${role == "student" ? "roll/email" : "email"} under $role.', true);
        return;
      }

      // Success → route by selected role
      if (!mounted) return;
      switch (_role) {
        case AppRole.student:
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StudentHome()));
          break;
        case AppRole.teacher:
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TeacherHome()));
          break;
        case AppRole.admin:
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminHome()));
          break;
      }
    } catch (e) {
      _snack(e.toString(), true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1D4ED8);
    const blueLight = Color(0xFF3B82F6);
    final textTheme = Theme.of(context).textTheme;

    final inputLabel = _role == AppRole.student
        ? 'Roll no. or KIIT Email'
        : 'KIIT Email';
    final inputHint = _role == AppRole.student
        ? 'e.g., 2230265  or  2230265@kiit.ac.in'
        : 'e.g., john.doe@kiit.ac.in';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // soft radial wash
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.35),
                  radius: 1.0,
                  colors: [Colors.white, Color(0xFFF4F7FF)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ),
          // faint blob
          Positioned(
            left: -90, top: -90,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle, color: blue.withOpacity(0.08)),
            ).animate().fadeIn(duration: 700.ms),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // header
                  Column(
                    children: [
                      SizedBox(
                        width: 200, height: 200,
                        child: Stack(alignment: Alignment.center, children: [
                          Container(
                            width: 170, height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: blue.withOpacity(0.08),
                              boxShadow: [BoxShadow(color: blue.withOpacity(0.35), blurRadius: 60, spreadRadius: 10)],
                            ),
                          )
                              .animate()
                              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.03, 1.03), duration: 900.ms, curve: Curves.easeInOut)
                              .then()
                              .scale(begin: const Offset(1.03, 1.03), end: const Offset(1.00, 1.00), duration: 700.ms, curve: Curves.easeOut),
                          Image.asset('assets/images/logo.png', width: 150, height: 150)
                              .animate()
                              .scale(begin: const Offset(0.82, 0.82), end: const Offset(1, 1), duration: 650.ms, curve: Curves.easeOutBack)
                              .fadeIn(duration: 650.ms)
                              .shimmer(colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.35)], duration: 800.ms, delay: 1100.ms),
                        ]),
                      ),
                      Text('ProjectEdu',
                          style: textTheme.headlineSmall?.copyWith(
                            color: blue,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ))
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 150.ms)
                          .slideY(begin: 0.15, end: 0, duration: 500.ms),
                      const SizedBox(height: 8),
                      Container(
                        width: 150, height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [blue, blueLight]),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [BoxShadow(color: blueLight.withOpacity(0.35), blurRadius: 10, spreadRadius: 1)],
                        ),
                      ).animate().fadeIn(duration: 450.ms, delay: 450.ms).scaleX(begin: 0.2, end: 1, duration: 450.ms),
                      const SizedBox(height: 26),
                    ],
                  ),

                  // role selector + card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE6EAF3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 28, offset: const Offset(0, 14))],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _RoleSelector(
                            selected: _role,
                            onChanged: (r) {
                              setState(() => _role = r);
                            },
                          ),
                          const SizedBox(height: 14),
                          _FieldWrapper(
                            child: TextFormField(
                              controller: _emailOrRoll,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: inputLabel,
                                hintText: inputHint,
                                prefixIcon: const Icon(Icons.account_circle_outlined),
                                border: InputBorder.none,
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) {
                                  return _role == AppRole.student
                                      ? 'Enter roll no. or KIIT email'
                                      : 'Enter your KIIT email';
                                }
                                if (_role == AppRole.student) {
                                  if (!_validateStudentFormat(value)) {
                                    return 'Enter roll (digits) or roll@kiit.ac.in';
                                  }
                                } else {
                                  if (!_validateStaffFormat(value)) {
                                    return 'Use your @kiit.ac.in email (no roll numbers)';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity, height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: blue.withOpacity(0.12),
                                foregroundColor: blue,
                                elevation: 0,
                                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              onPressed: _isSubmitting ? null : _continue,
                              child: _isSubmitting
                                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Continue'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _role == AppRole.student
                                ? 'Tip: you can type only your roll number, we’ll add @kiit.ac.in.'
                                : 'Only KIIT staff emails allowed here.',
                            style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 150.ms)
                      .moveY(begin: 12, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final AppRole selected;
  final ValueChanged<AppRole> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      _chip(context, AppRole.student, 'Student', Icons.school_outlined),
      _chip(context, AppRole.teacher, 'Supervisor', Icons.supervisor_account_outlined),
      _chip(context, AppRole.admin, 'Coordinator', Icons.admin_panel_settings_outlined),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }

  Widget _chip(BuildContext context, AppRole role, String label, IconData icon) {
    final isSelected = selected == role;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? scheme.primary : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? scheme.primary : Colors.black87),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? scheme.primary : Colors.black87)),
          ],
        ),
      ),
    );
  }
}

/// A rounded, elevated container for inputs (glassmorphism vibe).
class _FieldWrapper extends StatelessWidget {
  final Widget child;
  const _FieldWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}
