import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../screens/main_layout.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/packet_tracing_screen.dart';
import '../../screens/firewall_logs_screen.dart';
import '../../screens/virus_scanner_screen.dart';
import '../../screens/ip_analysis_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/threat_response_screen.dart';
import '../../screens/ai_analyst_screen.dart';
import '../../screens/investigation_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/create_account_screen.dart';
import '../../providers/auth_provider.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final bool isAuth = authProvider.isAuthenticated;
        final bool isLoggingIn = state.uri.path == '/login' ||
            state.uri.path == '/forgot-password' ||
            state.uri.path == '/create-account';

        if (!isAuth && !isLoggingIn) {
          return '/login';
        }

        if (isAuth && isLoggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/create-account',
          name: 'create-account',
          builder: (context, state) => const CreateAccountScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/packet-tracing',
              name: 'packet-tracing',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const PacketTracingScreen(),
              ),
            ),
            GoRoute(
              path: '/firewall-logs',
              name: 'firewall-logs',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const FirewallLogsScreen(),
              ),
            ),
            GoRoute(
              path: '/threat-response',
              name: 'threat-response',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const ThreatResponseScreen(),
              ),
            ),
            GoRoute(
              path: '/virus-scanner',
              name: 'virus-scanner',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const VirusScannerScreen(),
              ),
            ),
            GoRoute(
              path: '/ip-analysis',
              name: 'ip-analysis',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const IPAnalysisScreen(),
              ),
            ),
            GoRoute(
              path: '/reports',
              name: 'reports',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const ReportsScreen(),
              ),
            ),
            GoRoute(
              path: '/ai-analyst',
              name: 'ai-analyst',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const AIAnalystScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
              ),
            ),
            GoRoute(
              path: '/investigation/:id',
              name: 'investigation',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: InvestigationScreen(
                  alertId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
