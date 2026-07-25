import 'dart:io' show exit;
import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
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
import 'providers/capture_capability_provider.dart';
import 'core/app_environment.dart';
import 'core/sidecar/sidecar_manager_interface.dart';
import 'core/api/clients/local_agent_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppEnvironment.validate();

    // Sidecar uses dart:io (Process, ServerSocket) — not available on web.
    // On web the FastAPI backend is expected to be already running.
    if (!kIsWeb) {
      final sidecarManager = SidecarManager();
      await sidecarManager.start();
      if (sidecarManager.port != null) {
        LocalAgentClient.setBaseUrl('http://127.0.0.1:${sidecarManager.port}');
      }
    }

    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      publishableKey: AppEnvironment.supabasePublishableKey,
    );

    runApp(
      _SidecarLifecycle(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CaptureCapabilityProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => IntegrationsProvider()),
            ChangeNotifierProvider(create: (_) => AppStateProvider()),
            ChangeNotifierProvider(create: (_) => MetricsProvider()),
            ChangeNotifierProxyProvider<SettingsProvider, DashboardProvider>(
              create: (_) => DashboardProvider(),
              update: (_, settings, dashboard) => dashboard!
                ..updateRefreshInterval(settings.refreshInterval.duration),
            ),
            ChangeNotifierProvider(create: (_) => PacketTracingProvider()),
            ChangeNotifierProxyProvider<SettingsProvider, FirewallLogsProvider>(
              create: (_) => FirewallLogsProvider(),
              update: (_, settings, logs) => logs!
                ..updateRefreshInterval(settings.refreshInterval.duration),
            ),
            ChangeNotifierProxyProvider<SettingsProvider,
                FirewallActionsProvider>(
              create: (_) => FirewallActionsProvider(),
              update: (_, settings, actions) => actions!
                ..updateRefreshInterval(settings.refreshInterval.duration),
            ),
            ChangeNotifierProvider(create: (_) => VirusScannerProvider()),
            ChangeNotifierProvider(create: (_) => ThreatIntelProvider()),
            ChangeNotifierProvider(create: (_) => ThreatResponseProvider()),
            ChangeNotifierProvider(create: (_) => ReportsProvider()),
            ChangeNotifierProvider(create: (_) => ChatbotProvider()),
          ],
          child: const CyberSentinelApp(),
        ),
      ),
    );
  } catch (error) {
    debugPrint('[CyberSentinel] Startup failed (code logged in debug only).');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _StartupErrorScreen(error: error),
      ),
    );
  }
}

class _SidecarLifecycle extends StatefulWidget {
  final Widget child;
  const _SidecarLifecycle({required this.child});

  @override
  State<_SidecarLifecycle> createState() => _SidecarLifecycleState();
}

class _SidecarLifecycleState extends State<_SidecarLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(SidecarManager().stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(SidecarManager().stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StartupErrorScreen extends StatelessWidget {
  final Object? error;
  const _StartupErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    // Extract typed error code for debug display only — never show raw paths/exceptions.
    String? errorCode;
    final err = error;
    if (err != null) {
      final str = err.toString();
      // SidecarException serialises as 'SidecarException: code - message'
      if (str.startsWith('SidecarException: ')) {
        final rest = str.substring('SidecarException: '.length);
        errorCode = rest.split(' - ').first;
      } else if (err is StateError) {
        errorCode = 'authentication_configuration_missing';
      } else {
        errorCode = 'startup_failed';
      }
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'CyberSentinel local services could not be started.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'The local analysis service is unavailable. Retry the startup or review the development configuration.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => exit(0),
                    child: const Text('Exit'),
                  ),
                ],
              ),
              if (kDebugMode && errorCode != null) ...[
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text(
                    'Technical Details',
                    style: TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SelectableText(
                        'Error code:\n$errorCode',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
