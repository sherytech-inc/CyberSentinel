import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_state_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/packet_tracing_provider.dart';
import 'providers/firewall_logs_provider.dart';
import 'providers/virus_scanner_provider.dart';
import 'providers/ip_analysis_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PacketTracingProvider()),
        ChangeNotifierProvider(create: (_) => FirewallLogsProvider()),
        ChangeNotifierProvider(create: (_) => VirusScannerProvider()),
        ChangeNotifierProvider(create: (_) => IPAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const CyberSentinelApp(),
    ),
  );
}
