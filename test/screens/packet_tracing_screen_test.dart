import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cybersentinel/screens/packet_tracing_screen.dart';
import 'package:cybersentinel/providers/packet_tracing_provider.dart';
import 'package:cybersentinel/models/packet.dart';

void main() {
  late PacketTracingProvider provider;

  setUp(() {
    provider = PacketTracingProvider();
    // Inject mock packets directly for testing
    provider.injectMockPackets([
      Packet(
        id: '1',
        ip: '192.168.1.1',
        port: 80,
        protocol: 'HTTP',
        size: '500 B',
        status: PacketStatus.benign,
        timestamp: '10:00:00',
      ),
      Packet(
        id: '2',
        ip: '10.0.0.2',
        port: 443,
        protocol: 'HTTPS',
        size: '1.2 KB',
        status: PacketStatus.suspicious,
        timestamp: '10:00:05',
        threatScore: 65.0,
        severity: 'MEDIUM',
      ),
    ]);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<PacketTracingProvider>.value(
        value: provider,
        child: const Scaffold(
          body: PacketTracingScreen(),
        ),
      ),
    );
  }

  testWidgets('test_packet_table_uses_attached_vertical_scroll_controller', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    
    final scrollbars = find.byType(Scrollbar);
    expect(scrollbars, findsWidgets);

    // Scrollbars should be attached without throwing exceptions
    await tester.fling(find.byType(SingleChildScrollView).first, const Offset(0, -100), 1000, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_packet_table_can_scroll_without_scrollbar_exception', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.fling(find.byType(SingleChildScrollView).first, const Offset(0, -100), 1000, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_horizontal_scroll_handles_narrow_width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    final horizontalScroll = find.byType(SingleChildScrollView).last;
    await tester.fling(horizontalScroll, const Offset(-100, 0), 1000, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_no_overflow_at_1440_width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_no_overflow_at_1280_width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_no_overflow_at_1024_width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_selecting_row_uses_stable_id', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    
    await tester.pumpWidget(buildTestWidget());
    expect(provider.selectedPacketId, isNull);
    
    await tester.tap(find.text('192.168.1.1').first);
    await tester.pumpAndSettle();
    expect(provider.selectedPacketId, '1');
  });

  testWidgets('test_clicking_selected_row_clears_selection', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.text('192.168.1.1').first);
    await tester.pumpAndSettle();
    expect(provider.selectedPacketId, '1');
    
    await tester.tap(find.text('192.168.1.1').first);
    await tester.pumpAndSettle();
    expect(provider.selectedPacketId, isNull);
  });

  testWidgets('test_selection_survives_packet_reorder', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.text('192.168.1.1').first);
    await tester.pumpAndSettle();
    expect(provider.selectedPacketId, '1');
    
    provider.injectMockPackets(provider.packets.reversed.toList());
    await tester.pumpAndSettle();
    expect(provider.selectedPacketId, '1');
  });

  testWidgets('test_selection_clears_when_packet_disappears', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.text('192.168.1.1').first);
    await tester.pumpAndSettle();
    expect(provider.selectedPacketId, '1');
    
    provider.injectMockPackets([provider.packets[1]]);
    await tester.pumpAndSettle();
    expect(provider.selectedPacketId, isNull);
  });

  testWidgets('test_detail_panel_labels_ml_classification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.text('10.0.0.2').first);
    await tester.pumpAndSettle();
    
    expect(find.text('ML Classification'), findsOneWidget);
    expect(find.text('SUSPICIOUS'), findsWidgets); // Appears in table and detail panel
  });

  testWidgets('test_detail_panel_labels_decision_severity', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.text('10.0.0.2').first);
    await tester.pumpAndSettle();
    
    expect(find.text('Decision Severity'), findsOneWidget);
    expect(find.text('MEDIUM'), findsWidgets);
    expect(find.text('Final Risk Score'), findsOneWidget);
    expect(find.text('65.0 / 100'), findsOneWidget);
  });
}
