import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class CyberSentinelApp extends StatelessWidget {
  const CyberSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CyberSentinel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bgPrimary,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: AppTheme.bgSecondary,
          background: AppTheme.bgPrimary,
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
