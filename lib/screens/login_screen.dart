import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';
import 'student_home.dart';
import 'teacher_home.dart';
import 'admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isKiitEmail(String email) {
    final e = email.trim().toLowerCase();
    return e.endsWith('@kiit.ac.in');
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final client = SupabaseInit.client;
    try {
      final authRes = await client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      final user = authRes.user;
      if (user == null) throw 'Authentication failed.';

      final profile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        throw 'Profile not found. Contact the coordinator.';
      }

      final role = (profile['role'] ?? '').toString();

      if (!mounted) return;
      switch (role) {
        case 'admin':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminHome()),
          );
          break;
        case 'teacher':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TeacherHome()),
          );
          break;
        case 'student':
        default:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentHome()),
          );
          break;
      }
    } on AuthException catch (e) {
      _showSnack(e.message, true);
    } catch (e) {
      _showSnack(e.toString(), true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1D4ED8);
    const blueLight = Color(0xFF3B82F6);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft radial wash so the white isn't flat
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.35),
                  radius: 1.0,
                  colors: [Colors.white, Color(0xFFF4F7FF)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Top-left translucent blob
          Positioned(
            left: -90,
            top: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blue.withOpacity(0.08),
              ),
            ).animate().fadeIn(duration: 700.ms),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo + wordmark + underline accent
                  Column(
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // glow
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: blue.withOpacity(0.08),
                                boxShadow: [
                                  BoxShadow(
                                    color: blue.withOpacity(0.35),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1.03, 1.03),
                              duration: 900.ms,
                              curve: Curves.easeInOut,
                            )
                                .then()
                                .scale(
                              begin: const Offset(1.03, 1.03),
                              end: const Offset(1.00, 1.00),
                              duration: 700.ms,
                              curve: Curves.easeOut,
                            ),
                            // logo
                            Image.asset(
                              'lib/assets/images/logo.png',
                              width: 150,
                              height: 150,
                            )
                                .animate()
                                .scale(
                              begin: const Offset(0.82, 0.82),
                              end: const Offset(1, 1),
                              duration: 650.ms,
                              curve: Curves.easeOutBack,
                            )
                                .fadeIn(duration: 650.ms)
                                .shimmer(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.35)
                              ],
                              duration: 800.ms,
                              delay: 1100.ms,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'ProjectEdu',
                        style: textTheme.headlineSmall?.copyWith(
                          color: blue,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 150.ms)
                          .slideY(begin: 0.15, end: 0, duration: 500.ms),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient:
                          const LinearGradient(colors: [blue, blueLight]),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: blueLight.withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 450.ms, delay: 450.ms)
                          .scaleX(begin: 0.2, end: 1, duration: 450.ms),
                      const SizedBox(height: 26),
                    ],
                  ),

                  // Glass card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE6EAF3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          _FieldWrapper(
                            child: TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'KIIT Email',
                                hintText: 'rollno@kiit.ac.in',
                                prefixIcon: Icon(Icons.mail_outline),
                                border: InputBorder.none,
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'Enter your KIIT email';
                                if (!value.contains('@')) return 'Invalid email';
                                if (!_isKiitEmail(value)) {
                                  return 'Use your @kiit.ac.in email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password
                          _FieldWrapper(
                            child: TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                ),
                              ),
                              validator: (v) {
                                if ((v ?? '').length < 6) {
                                  return 'Min 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sign In button (with subtle gradient)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    blue.withOpacity(0.12),
                                    blueLight.withOpacity(0.12),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: blue.withOpacity(0.10),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  foregroundColor: blue,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: _isSubmitting ? null : _signIn,
                                child: _isSubmitting
                                    ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text('Sign In'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Only KIIT email addresses are allowed.',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
