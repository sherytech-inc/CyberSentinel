import 'dart:async';

import 'package:cybersentinel/models/scan_result.dart';
import 'package:cybersentinel/providers/virus_scanner_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> result(String type, String target,
        {String status = 'completed'}) =>
    {
      'scan_type': type,
      'target': target,
      'status': status,
      'verdict': 'clean',
      'malicious': 0,
      'suspicious': 0,
      'harmless': 70,
      'undetected': 0,
      'message': status == 'not_found'
          ? 'No existing VirusTotal report was found for this hash.'
          : 'Scan completed.'
    };

void main() {
  test('invalid URL and hash are rejected without network calls', () async {
    var calls = 0;
    final provider = VirusScannerProvider(
      urlRequest: (_) async {
        calls++;
        return {};
      },
      hashRequest: (_) async {
        calls++;
        return {};
      },
    );
    provider.setUrlInput('ftp://example.com');
    await provider.scanUrl();
    provider.setHashInput('not-a-supported-hash');
    await provider.scanHash();
    expect(calls, 0);
    expect(provider.urlError, 'Enter a valid HTTP or HTTPS URL.');
    expect(provider.hashError, 'Enter a valid MD5, SHA-1, or SHA-256 hash.');
  });

  test('normalized URL result renders without map/string casts', () async {
    final provider =
        VirusScannerProvider(urlRequest: (url) async => result('url', url));
    provider.setUrlInput('https://example.com');
    await provider.scanUrl();
    expect(provider.urlResult?.status, ScanStatus.completed);
    expect(provider.urlError, isNull);
  });

  test('map-shaped upstream error is never cast or exposed', () async {
    final provider = VirusScannerProvider(
        urlRequest: (_) async => {
              'error': true,
              'message': {'upstream': 'raw body'}
            });
    provider.setUrlInput('https://example.com');
    await provider.scanUrl();
    expect(provider.urlError, 'VirusTotal is temporarily unavailable.');
    expect(provider.urlError, isNot(contains('raw body')));
  });

  test('unknown valid hash is a result rather than a crash', () async {
    final hash = List.filled(64, '0').join();
    final provider = VirusScannerProvider(
        hashRequest: (value) async =>
            result('hash', value, status: 'not_found'));
    provider.setHashInput(hash);
    await provider.scanHash();
    expect(provider.hashResult?.status, ScanStatus.notFound);
    expect(provider.hashError, isNull);
  });

  test('duplicate file submission is disabled while uploading', () async {
    final pending = Completer<Map<String, dynamic>>();
    var calls = 0;
    final provider = VirusScannerProvider(fileRequest: (_, __) {
      calls++;
      return pending.future;
    });
    provider.selectFile('sample.bin', [1, 2, 3]);
    final first = provider.scanSelectedFile();
    await provider.scanSelectedFile();
    expect(calls, 1);
    expect(provider.fileScanning, isTrue);
    pending.complete(result('file', 'sample.bin'));
    await first;
    expect(provider.fileResult?.status, ScanStatus.completed);
  });

  test('detects supported hash type and keeps recent results in memory',
      () async {
    final hash = List.filled(40, 'a').join();
    final provider = VirusScannerProvider(
      hashRequest: (value) async => result('hash', value),
    );
    provider.setHashInput(hash);
    expect(provider.detectedHashType, 'SHA-1');
    await provider.scanHash();
    expect(provider.recentScans, hasLength(1));
    expect(provider.recentScans.first.target, hash);
  });

  test('selected file metadata can be removed without clearing other inputs',
      () {
    final provider = VirusScannerProvider();
    provider.setUrlInput('https://example.com');
    provider.selectFile('sample.bin', [1, 2, 3, 4]);
    expect(provider.selectedFileSize, 4);
    provider.removeSelectedFile();
    expect(provider.hasSelectedFile, isFalse);
    expect(provider.urlInput, 'https://example.com');
  });

  test('clear invalidates an in-flight file result', () async {
    final pending = Completer<Map<String, dynamic>>();
    final provider = VirusScannerProvider(
      fileRequest: (_, __) => pending.future,
    );
    provider.selectFile('sample.txt', [1, 2, 3]);
    final request = provider.scanSelectedFile();
    provider.clear();
    pending.complete(result('file', 'sample.txt'));
    await request;
    expect(provider.fileResult, isNull);
    expect(provider.fileScanning, isFalse);
    expect(provider.recentScans, isEmpty);
  });

  test('canonical complete status is accepted', () {
    final parsed = ScanResult.fromJson(
      result('url', 'https://example.com', status: 'complete'),
    );
    expect(parsed.status, ScanStatus.completed);
  });

  test('normalized failed result remains safe and usable', () async {
    final provider = VirusScannerProvider(
      hashRequest: (hash) async => {
        'error': true,
        'message': 'Provider returned an invalid analysis response.',
        'data': {
          'scan_type': 'hash',
          'target': hash,
          'status': 'failed',
          'verdict': 'unknown',
          'message': 'Provider returned an invalid analysis response.',
        },
      },
    );
    provider.setHashInput(List.filled(64, 'a').join());
    await provider.scanHash();
    expect(provider.hashResult?.status, ScanStatus.failed);
    expect(provider.hashError, isNull);
  });
}
