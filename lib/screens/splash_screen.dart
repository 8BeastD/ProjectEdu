import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Exactly ~3s before navigating to Login
    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1D4ED8); // deep blue to match your 3D logo
    const blueLight = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: Colors.white, // crisp white to make the 3D logo pop
      body: Stack(
        children: [
          // Subtle radial highlight on white
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [Colors.white, Color(0xFFF5F8FF)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Logo + glow + title
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Neon glow behind the logo (soft pulse)
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer soft glow
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: blue.withOpacity(0.10),
                          boxShadow: [
                            BoxShadow(
                              color: blue.withOpacity(0.45),
                              blurRadius: 60,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.04, 1.04),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      )
                          .then(delay: 100.ms)
                          .scale(
                        begin: const Offset(1.04, 1.04),
                        end: const Offset(1.00, 1.00),
                        duration: 700.ms,
                        curve: Curves.easeOut,
                      ),

                      // Your 3D logo
                      Image.asset(
                        'lib/assets/images/logo.png',
                        width: 140,
                        height: 140,
                      )
                          .animate()
                      // pop-in + fade (0–700ms)
                          .scale(
                        begin: const Offset(0.80, 0.80),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      )
                          .fadeIn(duration: 700.ms)
                      // gentle shine sweep (1200–2000ms)
                          .shimmer(
                        colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.35)],
                        duration: 800.ms,
                        delay: 1200.ms,
                      )
                      // slight lift before transition (2400–3000ms)
                          .then(delay: 400.ms)
                          .moveY(begin: 0, end: -6, duration: 400.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Title
                Text(
                  'ProjectEdu',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: blue,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 250.ms)
                    .slideY(begin: 0.18, end: 0, duration: 600.ms, curve: Curves.easeOut),

                // Thin accent underline that grows in
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [blue, blueLight]),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: blueLight.withOpacity(0.35), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 450.ms, delay: 600.ms)
                    .scaleX(begin: 0.2, end: 1, duration: 450.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
