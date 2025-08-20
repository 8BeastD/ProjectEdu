import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supabase_config.dart';
import 'package:projectedu/features/projects/screens/splash_screen.dart';
import 'package:projectedu/features/projects/screens/join_group_screen.dart';
import 'package:projectedu/features/projects/screens/create_group_screen.dart';
import 'package:projectedu/features/projects/screens/submit_proposal_screen.dart';
import 'package:projectedu/features/projects/screens/teacher_review_screen.dart';
import 'package:projectedu/features/projects/screens/group_details_screen.dart';
import 'package:projectedu/features/projects/screens/student_home.dart';
import 'package:projectedu/features/projects/screens/teacher_home.dart';
import 'package:projectedu/features/projects/screens/admin_home.dart';
import 'package:projectedu/features/projects/screens/coordinator_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseInit.init();
  runApp(const ProjectEduApp());
}

class ProjectEduApp extends StatelessWidget {
  const ProjectEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.light,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF667085)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      }),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProjectEdu',
      theme: theme,

      // 🔗 Named routes wired to your screens folder
      routes: {
        // homes (optional, helpful during wiring)
        '/home/student': (_) => const StudentHome(),
        '/home/teacher': (_) => const TeacherHome(),
        '/home/admin': (_) => const AdminHome(),

        // projects flow
        '/projects/create-group': (_) => const CreateGroupScreen(),
        '/projects/join-group': (_) => const JoinGroupScreen(),
        '/projects/submit-proposal': (_) => const SubmitProposalScreen(),
        '/projects/review-groups': (_) => const TeacherReviewScreen(),
        '/projects/group-details': (_) => const GroupDetailsScreen(groupId: '',),
        '/projects/settings': (_) => const CoordinatorSettingsScreen(),
      },

      // Friendly fallback if an unknown route is used
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => _RouteNotFoundScreen(missingRoute: settings.name ?? 'unknown'),
          settings: settings,
        );
      },

      // start on splash
      home: const SplashScreen(),
    );
  }
}

class _RouteNotFoundScreen extends StatelessWidget {
  final String missingRoute;
  const _RouteNotFoundScreen({required this.missingRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Coming Soon')),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, size: 42, color: Color(0xFF2563EB)),
              const SizedBox(height: 12),
              Text(
                'Route not found',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'The route "$missingRoute" is not wired yet.\nAdd it in MaterialApp.routes or onGenerateRoute.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF475467)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
