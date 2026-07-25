import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/api/clients/local_agent_client.dart';
import '../models/chat_message.dart';
import 'session_cleanup_coordinator.dart';

typedef CopilotSender = Future<Map<String, dynamic>> Function(
    String sessionId, String message);

class ChatbotProvider extends ChangeNotifier {
  ChatbotProvider({CopilotSender? sender})
      : _sender = sender ?? LocalAgentClient.sendCopilotMessage {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  static const _safeUnavailable =
      'AI Analyst is temporarily unavailable. Packet capture and threat monitoring are still running.';
  final CopilotSender _sender;
  String _sessionId = const Uuid().v4();
  String get sessionId => _sessionId;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<String> _suggestedQuestions = const [
    'Summarize the current capture session.',
    'Is monitoring currently active?',
    'How many packets were captured and analyzed?',
    'Why is analysis still pending?',
    'Explain the latest analyzed flow.',
    'Are there any suspicious IPs?',
    'Which models contributed to the latest result?',
    'What action should I take?',
  ];
  List<String> get suggestedQuestions => _suggestedQuestions;

  Future<void> sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      text: message,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _sender(_sessionId, message);
      final response = result['response'];
      if (response is String && response.trim().isNotEmpty) {
        _addBotMessage(response.trim());
      } else if (result['error'] == true) {
        _addBotMessage(_safeUnavailable);
      } else {
        _addBotMessage(_safeUnavailable);
      }
    } catch (_) {
      _addBotMessage(_safeUnavailable);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addBotMessage(String text) {
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      text: text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));
  }

  void clear() {
    _messages.clear();
    _isLoading = false;
    _sessionId = const Uuid().v4();
    notifyListeners();
  }
}
