import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

enum MessageSender { user, bot }

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  /// Whether the text field currently has any non-whitespace input.
  /// Used to control the send button gradient reactively.
  bool _hasText = false;

  final List<Message> _messages = [
    Message(
      id: '1',
      text:
          "Hello! I'm your CyberSentinel AI assistant. How can I help you with security monitoring today?",
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Listen to text changes so the send button gradient updates reactively.
    // The original code read _textController.text directly inside the build
    // method without a listener, so the button never changed colour.
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _textController.clear();
      // _hasText resets via the listener automatically on clear()
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate bot response delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final botResponse = _generateBotResponse(text);
    final botMessage = Message(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: botResponse,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(botMessage);
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _generateBotResponse(String userInput) {
    final input = userInput.toLowerCase();

    if (input.contains('threat') || input.contains('attack')) {
      return "Based on current monitoring, we've detected 3 suspicious activities in the last hour. The threat score is at 72/100. Would you like me to show you the detailed threat analysis?";
    } else if (input.contains('packet') || input.contains('traffic')) {
      return "Real-time traffic monitoring shows 8,432 packets/min with 94.2% classified as normal. I can help you filter packets by protocol or risk level. What would you like to analyze?";
    } else if (input.contains('firewall') || input.contains('logs')) {
      return "Your firewall has blocked 147 connection attempts today. The most active blocked IP is 185.220.101.42. Would you like to see the full firewall log analysis?";
    } else if (input.contains('ip') || input.contains('address')) {
      return "I can analyze any IP address for you. Just provide the IP and I'll check its geolocation, reputation score, and recent activity. What IP would you like to investigate?";
    } else if (input.contains('virus') ||
        input.contains('scan') ||
        input.contains('malware')) {
      return "The virus scanner is ready. You can upload files for analysis or provide a URL to scan. All scans use multiple threat detection engines. Would you like to start a scan?";
    } else if (input.contains('help') || input.contains('what can you do')) {
      return "I can help you with:\n• Threat analysis and monitoring\n• Packet tracing and classification\n• Firewall log insights\n• IP reputation checks\n• Virus scanning\n• Security reports\n• System settings\n\nJust ask me anything!";
    } else if (input.contains('report')) {
      return "I can generate comprehensive security reports with threat trends, attack patterns, and KPIs. Reports can be exported as PDF. Would you like me to prepare a report for a specific time period?";
    } else {
      return "I understand you're asking about security monitoring. Could you be more specific? I can help with threats, packets, firewall logs, IP analysis, virus scanning, or reports.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Floating Action Button ────────────────────────────────────────
        Positioned(
          bottom: 24,
          right: 24,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1F2E), Color(0xFF0F1420)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _isOpen
                    ? const Color(0xFF2A2F3E)
                    : const Color(0xFF06B6D4).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isOpen
                      ? Colors.black.withOpacity(0.5)
                      : const Color(0xFF06B6D4).withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isOpen ? LucideIcons.x : LucideIcons.messageCircle,
                  key: ValueKey(_isOpen),
                  color: _isOpen
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF06B6D4),
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // ── Chat Panel ────────────────────────────────────────────────────
        if (_isOpen)
          Positioned(
            bottom: 96,
            right: 24,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 384,
                  height: 600,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1420),
                    border: Border.all(color: const Color(0xFF1A1F2E)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildMessagesList()),
                      _buildInputArea(),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Chat Header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1F2E),
            Color(0xFF1E2938),
            Color(0xFF1A1F2E),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF06B6D4).withOpacity(0.2),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF06B6D4).withOpacity(0.2),
                  const Color(0xFF2563EB).withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              LucideIcons.bot,
              color: Color(0xFF06B6D4),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CyberSentinel AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Security Assistant',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Messages List ──────────────────────────────────────────────────────────

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  // ── Input Area ─────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E1A),
        border: Border(top: BorderSide(color: Color(0xFF1A1F2E))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF06B6D4)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),

              // Send button — gradient now reacts to _hasText
              Container(
                decoration: BoxDecoration(
                  gradient: _hasText
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0891B2),
                            Color(0xFF0E7490),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF374151),
                            Color(0xFF1F2937),
                          ],
                        ),
                  border: Border.all(
                    color: _hasText
                        ? const Color(0xFF06B6D4).withOpacity(0.3)
                        : const Color(0xFF4B5563),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'AI-powered security assistant',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message Bubble ─────────────────────────────────────────────────────────

  Widget _buildMessageBubble(Message message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                    const Color(0xFF2563EB).withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.bot,
                color: Color(0xFFA78BFA),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
                          )
                        : null,
                    color: isUser ? null : const Color(0xFF1A1F2E),
                    border: Border.all(
                      color: isUser
                          ? const Color(0xFF06B6D4).withOpacity(0.3)
                          : const Color(0xFF2A2F3E),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFFE5E7EB),
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(0.1),
                    const Color(0xFF2563EB).withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.user,
                color: Color(0xFF06B6D4),
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing Indicator ───────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                  const Color(0xFF2563EB).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.bot,
              color: Color(0xFFA78BFA),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              border: Border.all(
                color: const Color(0xFF2A2F3E),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
                  child: _AnimatedDot(delay: index * 100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ── Animated Dot ───────────────────────────────────────────────────────────

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFFA78BFA),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
