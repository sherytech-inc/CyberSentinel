import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybersentinel/core/sidecar/sidecar_manager.dart';
import 'api_service.dart';

enum WebSocketState {
  disconnected,
  connecting,
  authenticating,
  connected,
  reconnecting,
  unauthorized,
  error
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  WebSocketState get state => _state;
  bool get isConnected => _state == WebSocketState.connected;

  // Stream controllers for different event types
  final _initialStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _packetBatchController = StreamController<Map<String, dynamic>>.broadcast();
  final _newThreatController = StreamController<Map<String, dynamic>>.broadcast();
  final _alertUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _alertResolvedController = StreamController<Map<String, dynamic>>.broadcast();
  final _statsUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  // Connection state updates
  final _connectionStateController = StreamController<WebSocketState>.broadcast();

  Stream<Map<String, dynamic>> get initialStateStream => _initialStateController.stream;
  Stream<Map<String, dynamic>> get packetBatchStream => _packetBatchController.stream;
  Stream<Map<String, dynamic>> get newThreatStream => _newThreatController.stream;
  Stream<Map<String, dynamic>> get alertUpdatedStream => _alertUpdatedController.stream;
  Stream<Map<String, dynamic>> get alertResolvedStream => _alertResolvedController.stream;
  Stream<Map<String, dynamic>> get statsUpdateStream => _statsUpdateController.stream;
  Stream<WebSocketState> get connectionStateStream => _connectionStateController.stream;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = true;
  StreamSubscription? _subscription;

  void _setState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _connectionStateController.add(newState);
    }
  }

  void connect() {
    _shouldReconnect = true;
    if (_channel != null) return;
    _setState(WebSocketState.connecting);

    final rawUrl = LocalAgentClient.baseUrl;
    String wsUrl;
    if (rawUrl.startsWith('https://')) {
      wsUrl = 'wss://${rawUrl.substring(8)}/ws/events';
    } else if (rawUrl.startsWith('http://')) {
      wsUrl = 'ws://${rawUrl.substring(7)}/ws/events';
    } else {
      wsUrl = 'ws://$rawUrl/ws/events';
    }

    if (kDebugMode) {
      print('Establishing unified WebSocket connection to $wsUrl');
    }
    _establishConnection(wsUrl);
  }

  Future<void> _establishConnection(String url) async {
    try {
      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(const Duration(seconds: 5));
      
      _channel = channel;
      _reconnectAttempts = 0;
      _setState(WebSocketState.authenticating);

      if (kDebugMode) {
        print('WebSocket connected, sending auth payload');
      }

      // Read latest token for this specific connection
      String? accessToken;
      try {
        final session = Supabase.instance.client.auth.currentSession;
        accessToken = session?.accessToken;
      } catch (e) {
        if (kDebugMode) print('Supabase not initialized or accessible (likely test environment)');
      }

      if (accessToken == null || accessToken.isEmpty) {
        if (kDebugMode) print('No session available for WebSocket auth');
        _handleDisconnect(url, unauthorized: true);
        return;
      }

      final payload = <String, dynamic>{
        'type': 'auth',
        'token': accessToken,
      };
      
      final localToken = SidecarManager().localToken;
      if (localToken != null) {
        payload['local_token'] = localToken;
      }

      channel.sink.add(jsonEncode(payload));

      _subscription = channel.stream.listen(
        (data) {
          _handleMessage(data as String);
        },
        onError: (err) {
          if (kDebugMode) {
            print('WebSocket error: $err');
          }
          _handleDisconnect(url);
        },
        onDone: () {
          if (kDebugMode) {
            print('WebSocket connection closed by server. Code: ${channel.closeCode}');
          }
          // Some backend implementations might send specific close codes for unauthorized (e.g. 4001, 4003)
          final bool isUnauthorized = channel.closeCode == 4001 || channel.closeCode == 4003 || channel.closeCode == 1008;
          _handleDisconnect(url, unauthorized: isUnauthorized);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect to WebSocket: $e');
      }
      _handleDisconnect(url);
    }
  }

  void _handleMessage(String data) {
    try {
      final envelope = jsonDecode(data) as Map<String, dynamic>;
      final eventType = envelope['type'] as String? ?? envelope['event_type'] as String?;
      final payload = envelope['payload'] as Map<String, dynamic>? ?? {};

      if (eventType == 'auth_ack') {
        final bool authenticated = envelope['authenticated'] == true || envelope['status'] == 'success';
        if (authenticated) {
          _setState(WebSocketState.connected);
          if (kDebugMode) print('WebSocket authenticated successfully');
        } else {
          _setState(WebSocketState.unauthorized);
          if (kDebugMode) print('WebSocket authentication failed');
          _channel?.sink.close(4001, 'Unauthorized');
        }
        return;
      }

      // Do not process operational events if not fully authenticated
      if (_state != WebSocketState.connected) {
        return;
      }

      switch (eventType) {
        case 'heartbeat':
          // Keep connection alive, no action needed
          break;
        case 'initial_state':
          _initialStateController.add(payload);
          break;
        case 'packet_batch':
          _packetBatchController.add(payload);
          break;
        case 'new_threat':
          _newThreatController.add(payload);
          break;
        case 'alert_updated':
          _alertUpdatedController.add(payload);
          break;
        case 'alert_resolved':
          _alertResolvedController.add(payload);
          break;
        case 'stats_update':
          _statsUpdateController.add(payload);
          break;
        default:
          if (kDebugMode) {
            print('Unknown WebSocket event type: $eventType');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling WebSocket message: $e');
      }
    }
  }

  void _handleDisconnect(String url, {bool unauthorized = false}) {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (unauthorized || !_shouldReconnect) {
      _shouldReconnect = false;
      _setState(unauthorized ? WebSocketState.unauthorized : WebSocketState.disconnected);
      return;
    }

    _setState(WebSocketState.error);

    // Exponential backoff strategy: 1s, 2s, 4s, 8s, up to 30s
    final delay = _getBackoffDelay(_reconnectAttempts);
    _reconnectAttempts++;

    if (kDebugMode) {
      print('WebSocket disconnected. Reconnecting in $delay seconds (attempt $_reconnectAttempts)...');
    }

    _reconnectTimer?.cancel();
    _setState(WebSocketState.reconnecting);
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      // Re-read token, refresh if necessary (this triggers _refreshToken via ApiService or Supabase explicitly if expired)
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null && session.isExpired) {
          try {
            await Supabase.instance.client.auth.refreshSession();
          } catch (_) {
            _setState(WebSocketState.unauthorized);
            return;
          }
        }
      } catch (e) {
        // Ignore if uninitialized
      }
      _establishConnection(url);
    });
  }

  int _getBackoffDelay(int attempt) {
    if (attempt == 0) return 1;
    if (attempt == 1) return 2;
    if (attempt == 2) return 4;
    if (attempt == 3) return 8;
    return 30;
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _setState(WebSocketState.disconnected);
  }

  void dispose() {
    disconnect();
    _initialStateController.close();
    _packetBatchController.close();
    _newThreatController.close();
    _alertUpdatedController.close();
    _alertResolvedController.close();
    _statsUpdateController.close();
    _connectionStateController.close();
  }
}
