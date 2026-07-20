import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/packet_tracing_provider.dart';
import 'providers/firewall_logs_provider.dart';
import 'providers/firewall_actions_provider.dart';
import 'providers/virus_scanner_provider.dart';
import 'providers/threat_intel_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/threat_response_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/chatbot_provider.dart';
import 'providers/metrics_provider.dart';
import 'providers/integrations_provider.dart';
import 'core/app_environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    AppEnvironment.validate();
    
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      anonKey: AppEnvironment.supabasePublishableKey,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => IntegrationsProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => MetricsProvider()),
          ChangeNotifierProxyProvider<SettingsProvider, DashboardProvider>(
            create: (_) => DashboardProvider(),
            update: (_, settings, dashboard) => dashboard!..updateRefreshInterval(settings.refreshInterval.duration),
          ),
          ChangeNotifierProvider(create: (_) => PacketTracingProvider()),
          ChangeNotifierProxyProvider<SettingsProvider, FirewallLogsProvider>(
            create: (_) => FirewallLogsProvider(),
            update: (_, settings, logs) => logs!..updateRefreshInterval(settings.refreshInterval.duration),
          ),
          ChangeNotifierProxyProvider<SettingsProvider, FirewallActionsProvider>(
            create: (_) => FirewallActionsProvider(),
            update: (_, settings, actions) => actions!..updateRefreshInterval(settings.refreshInterval.duration),
          ),
          ChangeNotifierProvider(create: (_) => VirusScannerProvider()),
          ChangeNotifierProvider(create: (_) => ThreatIntelProvider()),
          ChangeNotifierProvider(create: (_) => ThreatResponseProvider()),
          ChangeNotifierProvider(create: (_) => ReportsProvider()),
          ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ],
        child: const CyberSentinelApp(),
      ),
    );
  } catch (error) {
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _ConfigurationErrorScreen(),
      ),
    );
  }
}

class _ConfigurationErrorScreen extends StatelessWidget {
  const _ConfigurationErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'CyberSentinel configuration is incomplete.\nContact the application administrator.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
