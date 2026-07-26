import 'package:cybersentinel/core/theme/app_theme.dart';
import 'package:cybersentinel/providers/threat_intel_provider.dart';
import 'package:cybersentinel/screens/ip_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> partialResult(String ip) => {
      'ip': ip,
      'target': ip,
      'status': 'partial',
      'analysis_status': 'partial',
      'intel_score': null,
      'severity': 'N/A',
      'score_confidence': 'LIMITED',
      'providers_used': ['VIRUSTOTAL', 'GEOIP'],
      'providers_queried': ['VIRUSTOTAL', 'ABUSEIPDB', 'GEOIP'],
      'providers_available': ['VIRUSTOTAL', 'GEOIP'],
      'virustotal': {
        'status': 'completed',
        'malicious': 0,
        'suspicious': 0,
        'harmless': 60,
        'undetected': 10,
        'total_engines': 70,
      },
      'abuseipdb': {
        'status': 'quota_exceeded',
        'message': 'AbuseIPDB is rate limited.',
      },
      'geoip': {
        'status': 'completed',
        'country': 'United States',
        'region': 'California',
        'city': 'Mountain View',
        'isp': 'Example ISP',
        'asn': 'AS15169',
      },
      'message': 'Partial intelligence is available.',
      'looked_up_at': '2026-07-27T00:00:00Z',
      'cached': false,
    };

Widget app(ThreatIntelProvider provider) => ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppTheme.bgPrimary,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: IPAnalysisScreen(),
          ),
        ),
      ),
    );

void main() {
  testWidgets('partial intelligence remains truthful and narrow-layout safe',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(462, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = ThreatIntelProvider(
      request: (ip) async => partialResult(ip),
    );
    provider.setSearchQuery('8.8.8.8');
    await provider.analyzeIP();

    await tester.pumpWidget(app(provider));
    await tester.pumpAndSettle();

    expect(find.text('N/A'), findsOneWidget);
    expect(find.textContaining('PARTIAL'), findsOneWidget);
    expect(find.text('AbuseIPDB is rate limited.'), findsOneWidget);
    expect(find.textContaining('California'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
