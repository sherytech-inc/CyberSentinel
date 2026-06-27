import 'package:flutter_test/flutter_test.dart';
import 'package:cybersentinel/app.dart';

void main() {
  testWidgets('CyberSentinel app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const CyberSentinelApp());

    // Verify the app launches without throwing.
    // The main layout should render the sidebar navigation.
    expect(find.byType(CyberSentinelApp), findsOneWidget);
  });
}
