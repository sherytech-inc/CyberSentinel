import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
class CyberSentinelApp extends StatefulWidget {
  const CyberSentinelApp({super.key});

  @override
  State<CyberSentinelApp> createState() => _CyberSentinelAppState();
}

class _CyberSentinelAppState extends State<CyberSentinelApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Use read to only fetch it once for the router creation
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (auth.isLoading && !auth.isAuthenticated) {
      // Initial loading splash before auth state is fully loaded
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: AppTheme.bgPrimary),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'CyberSentinel',
      debugShowCheckedModeBanner: false,
      themeMode: context.watch<SettingsProvider>().themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),
        colorScheme: ColorScheme.light(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bgPrimary,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: AppTheme.bgPrimary,
        ),
      ),
      routerConfig: _router,
    );
  }
}
