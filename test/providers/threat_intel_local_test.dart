import 'dart:async';

import 'package:cybersentinel/models/intel_model.dart';
import 'package:cybersentinel/providers/threat_intel_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid IP is rejected locally', () async {
    var calls = 0;
    final provider = ThreatIntelProvider(request: (_) async {
      calls++;
      return {};
    });
    provider.setSearchQuery('not-an-ip');
    await provider.analyzeIP();
    expect(calls, 0);
    expect(provider.errorMessage, contains('not a valid IP address'));
  });

  test('private IP receives truthful skipped-provider result', () async {
    var calls = 0;
    final provider = ThreatIntelProvider(request: (ip) async {
      calls++;
      return {
        'ip': ip,
        'target': ip,
        'status': 'not_found',
        'analysis_status': 'failed',
        'providers_queried': [],
        'providers_available': [],
        'providers_used': [],
        'virustotal': {'status': 'skipped', 'message': 'Skipped.'},
        'abuseipdb': {'status': 'skipped', 'message': 'Skipped.'},
        'geoip': {'status': 'skipped', 'message': 'Skipped.'},
        'message': 'Public providers were skipped.',
        'looked_up_at': '2026-07-27T00:00:00Z',
      };
    });
    provider.setSearchQuery('192.168.1.1');
    await provider.analyzeIP();
    expect(calls, 1);
    expect(provider.errorMessage, isNull);
    expect(
        provider.intelResponse?.virustotal.status, IntelProviderStatus.skipped);
    expect(provider.intelResponse?.providersQueried, isEmpty);
  });

  test('IPv6 is accepted and duplicate lookup is prevented', () async {
    final pending = Completer<Map<String, dynamic>>();
    var calls = 0;
    final provider = ThreatIntelProvider(request: (_) {
      calls++;
      return pending.future;
    });
    provider.setSearchQuery('2606:4700:4700::1111');
    final first = provider.analyzeIP();
    await provider.analyzeIP();
    expect(calls, 1);
    pending.complete({
      'ip': '2606:4700:4700::1111',
      'status': 'partial',
      'analysis_status': 'partial',
      'providers_used': ['GEOIP'],
      'providers_queried': ['VIRUSTOTAL', 'ABUSEIPDB', 'GEOIP'],
      'providers_available': ['GEOIP'],
      'virustotal': {'status': 'unavailable'},
      'abuseipdb': {'status': 'unavailable'},
      'geoip': {'status': 'completed'},
      'message': 'Partial intelligence is available.',
      'looked_up_at': '2026-07-27T00:00:00Z',
    });
    await first;
    expect(provider.intelResponse?.analysisStatus, 'partial');
  });

  test('partial local-sidecar result remains usable', () async {
    final provider = ThreatIntelProvider(
        request: (ip) async => {
              'ip': ip,
              'status': 'partial',
              'analysis_status': 'partial',
              'intel_score': 12,
              'severity': 'Low',
              'score_confidence': 'LIMITED',
              'providers_used': ['GEOIP'],
              'providers_queried': ['VIRUSTOTAL', 'ABUSEIPDB', 'GEOIP'],
              'providers_available': ['GEOIP'],
              'virustotal': {
                'status': 'not_configured',
                'message': 'VirusTotal integration is not configured.'
              },
              'abuseipdb': {
                'status': 'unavailable',
                'message': 'AbuseIPDB is temporarily unavailable.'
              },
              'geoip': {'status': 'completed', 'country': 'United States'},
              'message': 'Results are partial.',
              'looked_up_at': '2026-07-21T00:00:00Z',
              'cached': false,
            });
    provider.setSearchQuery('8.8.8.8');
    await provider.analyzeIP();
    expect(provider.intelResponse?.status, IntelStatus.partial);
    expect(provider.errorMessage, isNull);
  });
}
