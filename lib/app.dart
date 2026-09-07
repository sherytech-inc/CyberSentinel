import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/common/common.dart';

ThemeData _darkTheme() => CsTheme.dark(
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

ThemeData _lightTheme() => CsTheme.light(
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );

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
        theme: _darkTheme(),
        home: const _StartupSplash(),
      );
    }

    return MaterialApp.router(
      title: 'CyberSentinel',
      debugShowCheckedModeBanner: false,
      themeMode: context.watch<SettingsProvider>().themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      routerConfig: _router,
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CyberSentinelLogo(size: 44),
            const SizedBox(height: CsSpacing.xl),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
