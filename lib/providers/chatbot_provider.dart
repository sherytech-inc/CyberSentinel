import 'package:cybersentinel/core/api/clients/cloud_control_plane_client.dart';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatbotProvider extends ChangeNotifier {
  ChatbotProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  final String _sessionId = const Uuid().v4();

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _suggestedQuestions = [
    "What are the top threats right now?",
    "Summarize recent firewall blocks.",
    "Analyze the IP address 185.220.101.42.",
    "Show me the latest packet tracing activity."
  ];
  List<String> get suggestedQuestions => _suggestedQuestions;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      final response = await CloudControlPlaneClient.sendChatMessage(_sessionId, text);

      if (response['error'] == true) {
        _addBotMessage("Sorry, an error occurred: ${response['message']}");
      } else {
        final botText = response['response'] ?? "I didn't understand that.";
        _addBotMessage(botText);
      }
    } catch (e) {
      _addBotMessage("Sorry, an error occurred: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addBotMessage(String text) {
    final botMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
    _messages.add(botMessage);
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
