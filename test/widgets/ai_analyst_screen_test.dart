import 'package:cybersentinel/providers/chatbot_provider.dart';
import 'package:cybersentinel/screens/ai_analyst_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

Widget _app(ChatbotProvider provider, {Widget? child}) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(
        body: child ?? const AIAnalystScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('narrow AI Analyst layout has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = ChatbotProvider(
      sender: (_, __) async => {'response': 'Monitoring is inactive.'},
    );

    await tester.pumpWidget(_app(provider));
    await tester.pump();

    expect(find.text('AI Security Analyst'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('safe failure keeps input enabled and hides raw errors',
      (tester) async {
    final provider = ChatbotProvider(
      sender: (_, __) async => throw Exception('secret-token raw stack'),
    );
    await tester.pumpWidget(_app(provider));

    await tester.enterText(
      find.byType(TextField),
      'Is monitoring currently active?',
    );
    await tester.tap(find.byIcon(LucideIcons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    expect(find.textContaining('secret-token'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('clear works and navigation does not duplicate messages',
      (tester) async {
    final provider = ChatbotProvider(
      sender: (_, __) async => {'response': 'Monitoring is inactive.'},
    );
    await tester.pumpWidget(_app(provider));
    await tester.enterText(find.byType(TextField), 'status');
    await tester.tap(find.byIcon(LucideIcons.send));
    await tester.pumpAndSettle();

    expect(find.text('Monitoring is inactive.'), findsOneWidget);
    final messageCount = provider.messages.length;

    await tester.pumpWidget(_app(provider, child: const SizedBox.shrink()));
    await tester.pumpWidget(_app(provider));
    await tester.pump();
    expect(provider.messages.length, messageCount);
    expect(find.text('Monitoring is inactive.'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear conversation'));
    await tester.pump();
    expect(provider.messages, isEmpty);
    expect(find.text('Monitoring is inactive.'), findsNothing);
  });
}
