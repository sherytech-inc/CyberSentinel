import 'dart:async';

import 'package:cybersentinel/models/chat_message.dart';
import 'package:cybersentinel/providers/chatbot_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('successful local response renders and duplicate send is prevented',
      () async {
    final completer = Completer<Map<String, dynamic>>();
    var calls = 0;
    final provider = ChatbotProvider(sender: (session, message) {
      calls++;
      return completer.future;
    });

    final first = provider.sendMessage('Is monitoring active?');
    await provider.sendMessage('duplicate');
    expect(provider.isLoading, isTrue);
    expect(calls, 1);
    expect(provider.messages.length, 1);

    completer
        .complete({'response': 'Monitoring is inactive.', 'available': true});
    await first;
    expect(provider.isLoading, isFalse);
    expect(provider.messages.last.sender, MessageSender.bot);
    expect(provider.messages.last.text, 'Monitoring is inactive.');
  });

  test('transport error is rendered safely and input recovers', () async {
    final provider = ChatbotProvider(sender: (_, __) async {
      throw Exception('secret-token raw stack');
    });

    await provider.sendMessage('summary');

    expect(provider.isLoading, isFalse);
    expect(provider.messages.last.text, contains('temporarily unavailable'));
    expect(provider.messages.last.text, isNot(contains('secret-token')));
  });

  test('clear resets messages and conversation session', () async {
    final provider =
        ChatbotProvider(sender: (_, __) async => {'response': 'ok'});
    final oldSession = provider.sessionId;
    await provider.sendMessage('hello');
    provider.clear();

    expect(provider.messages, isEmpty);
    expect(provider.sessionId, isNot(oldSession));
  });

  test('clear invalidates an in-flight response', () async {
    final completer = Completer<Map<String, dynamic>>();
    final provider = ChatbotProvider(sender: (_, __) => completer.future);

    final request = provider.sendMessage('hello');
    provider.clear();
    completer.complete({'response': 'stale response'});
    await request;

    expect(provider.messages, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('conversation messages remain bounded', () async {
    final provider =
        ChatbotProvider(sender: (_, message) async => {'response': message});

    for (var index = 0; index < 25; index++) {
      await provider.sendMessage('message-$index');
    }

    expect(provider.messages.length, ChatbotProvider.maxMessages);
    expect(provider.messages.last.text, 'message-24');
    expect(provider.messages.first.text, isNot(contains('message-0')));
  });

  test('suggested questions cover presentation scenarios', () {
    final provider = ChatbotProvider(sender: (_, __) async => {});
    expect(provider.suggestedQuestions,
        contains('Summarize the current capture session.'));
    expect(provider.suggestedQuestions,
        contains('Is monitoring currently active?'));
    expect(provider.suggestedQuestions,
        contains('Was threat intelligence available?'));
    expect(
        provider.suggestedQuestions, contains('Was this IP actually blocked?'));
    expect(provider.suggestedQuestions, contains('Can you generate a report?'));
    expect(provider.suggestedQuestions, contains('What action should I take?'));
  });
}
