import 'dart:async';
import 'dart:convert';

import 'package:cybersentinel/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Session session({
    required String tokenName,
    required DateTime expiresAt,
  }) {
    final header = base64Url
        .encode(utf8.encode(jsonEncode({'alg': 'none'})))
        .replaceAll('=', '');
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({
          'sub': '7996d00a-1c0d-4b64-b891-ace17d258025',
          'email': 'analyst@example.com',
          'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
          'token_name': tokenName,
        })))
        .replaceAll('=', '');
    return Session(
      accessToken: '$header.$payload.signature',
      tokenType: 'bearer',
      user: const User(
        id: '7996d00a-1c0d-4b64-b891-ace17d258025',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        email: 'analyst@example.com',
        createdAt: '2026-01-01T00:00:00Z',
        role: 'authenticated',
      ),
    );
  }

  test('overlapping auth events share one bootstrap operation', () async {
    final coordinator = AuthBootstrapCoordinator();
    final bootstrapStarted = Completer<void>();
    final releaseBootstrap = Completer<void>();
    var bootstrapCalls = 0;
    var refreshCalls = 0;
    final activeSession = session(
      tokenName: 'active',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    Future<void> bootstrap(String accessToken) async {
      bootstrapCalls++;
      bootstrapStarted.complete();
      await releaseBootstrap.future;
    }

    final first = coordinator.run(
      activeSession,
      refreshSession: () async {
        refreshCalls++;
        return activeSession;
      },
      bootstrap: bootstrap,
    );
    await bootstrapStarted.future;
    final second = coordinator.run(
      activeSession,
      refreshSession: () async {
        refreshCalls++;
        return activeSession;
      },
      bootstrap: bootstrap,
    );

    expect(coordinator.isInFlight, isTrue);
    expect(bootstrapCalls, 1);
    expect(refreshCalls, 0);

    releaseBootstrap.complete();
    await Future.wait([first, second]);
    expect(coordinator.isInFlight, isFalse);
    expect(bootstrapCalls, 1);
  });

  test('expired session refreshes once before bootstrap', () async {
    final coordinator = AuthBootstrapCoordinator();
    final expiredSession = session(
      tokenName: 'expired',
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    final refreshedSession = session(
      tokenName: 'refreshed',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    var refreshCalls = 0;
    String? bootstrappedToken;

    await coordinator.run(
      expiredSession,
      refreshSession: () async {
        refreshCalls++;
        return refreshedSession;
      },
      bootstrap: (accessToken) async {
        bootstrappedToken = accessToken;
      },
    );

    expect(refreshCalls, 1);
    expect(bootstrappedToken, refreshedSession.accessToken);
  });

  test('failed refresh never attempts bootstrap', () async {
    final coordinator = AuthBootstrapCoordinator();
    final expiredSession = session(
      tokenName: 'expired',
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    var bootstrapCalls = 0;

    await expectLater(
      coordinator.run(
        expiredSession,
        refreshSession: () async => null,
        bootstrap: (_) async {
          bootstrapCalls++;
        },
      ),
      throwsA(isA<AuthSessionExpiredException>()),
    );

    expect(bootstrapCalls, 0);
    expect(coordinator.isInFlight, isFalse);
  });
}
