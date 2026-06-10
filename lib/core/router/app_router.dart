import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/main_layout.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/packet_tracing_screen.dart';
import '../../screens/firewall_logs_screen.dart';
import '../../screens/virus_scanner_screen.dart';
import '../../screens/ip_analysis_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
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
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
