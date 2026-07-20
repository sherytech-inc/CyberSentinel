import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chatbot_provider.dart';
import '../models/chat_message.dart';
import '../core/theme/app_theme.dart';

class AIAnalystScreen extends StatefulWidget {
  const AIAnalystScreen({super.key});

  @override
  State<AIAnalystScreen> createState() => _AIAnalystScreenState();
}

class _AIAnalystScreenState extends State<AIAnalystScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSend(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    final provider = context.read<ChatbotProvider>();
    provider.sendMessage(text).then((_) => _scrollToBottom());
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.borderPrimary),
            ),
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, color: AppTheme.borderPrimary),
                Expanded(
                  child: Consumer<ChatbotProvider>(
                    builder: (context, provider, child) {
                      return _buildMessagesList(provider);
                    },
                  ),
                ),
                Consumer<ChatbotProvider>(
                  builder: (context, provider, child) {
                    if (provider.messages.isEmpty &&
                        provider.suggestedQuestions.isNotEmpty) {
                      return _buildSuggestedQuestions(context, provider);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Divider(height: 1, color: AppTheme.borderPrimary),
                _buildInputArea(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(LucideIcons.bot, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: AppTheme.spacing16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Security Analyst',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Powered by CyberSentinel Copilot',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatbotProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (provider.isLoading && index == provider.messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(provider.messages[index]);
      },
    );
  }

  Widget _buildSuggestedQuestions(
      BuildContext context, ChatbotProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: provider.suggestedQuestions.map((q) {
          return ActionChip(
            label: Text(q, style: const TextStyle(fontSize: 13)),
            backgroundColor: AppTheme.bgPrimary,
            side: const BorderSide(color: AppTheme.borderPrimary),
            onPressed: () => _handleSend(context, q),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask the AI Analyst a question...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.bgPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing16,
                ),
              ),
              onSubmitted: (val) => _handleSend(context, val),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.white),
              onPressed: () => _handleSend(context, _textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(LucideIcons.bot, size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: AppTheme.spacing12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : AppTheme.bgPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTheme.radiusLg),
                  topRight: const Radius.circular(AppTheme.radiusLg),
                  bottomLeft: Radius.circular(isUser ? AppTheme.radiusLg : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppTheme.radiusLg),
                ),
                border:
                    isUser ? null : Border.all(color: AppTheme.borderPrimary),
              ),
              child: isUser 
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
                        strong: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        listBullet: const TextStyle(color: AppTheme.primary),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppTheme.spacing12),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: const Icon(LucideIcons.user,
                  size: 16, color: AppTheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF1E293B),
            child: Icon(LucideIcons.bot, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLg),
                topRight: Radius.circular(AppTheme.radiusLg),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(AppTheme.radiusLg),
              ),
              border: Border.all(color: AppTheme.borderPrimary),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(delay: 0),
                SizedBox(width: 4),
                _AnimatedDot(delay: 150),
                SizedBox(width: 4),
                _AnimatedDot(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    )..repeat(reverse: true);

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
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
