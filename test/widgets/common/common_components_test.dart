import 'package:cybersentinel/widgets/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
    double width = 1200,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? CsTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  group('AppCard', () {
    testWidgets('renders title, subtitle, child and footer', (tester) async {
      await pump(
        tester,
        const AppCard(
          title: 'Threat overview',
          subtitle: 'Current session',
          icon: Icons.shield_outlined,
          footer: Text('Updated 2 minutes ago'),
          child: Text('12 alerts'),
        ),
      );

      expect(find.text('Threat overview'), findsOneWidget);
      expect(find.text('Current session'), findsOneWidget);
      expect(find.text('12 alerts'), findsOneWidget);
      expect(find.text('Updated 2 minutes ago'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports taps when interactive', (tester) async {
      var taps = 0;
      await pump(tester, AppCard(title: 'Selectable', onTap: () => taps++));

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a card without an action is not exposed as a button',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const AppCard(title: 'Static'));

      expect(find.byType(GestureDetector), findsNothing);
      handle.dispose();
    });

    testWidgets('renders in the light theme without throwing', (tester) async {
      await pump(
        tester,
        const AppCard(title: 'Light theme card', child: Text('body')),
        theme: CsTheme.light(),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('StatusBadge', () {
    testWidgets('keeps lifecycle states textually distinct', (tester) async {
      await pump(
        tester,
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge(status: StatusKind.success),
            StatusBadge(status: StatusKind.warning),
            StatusBadge(status: StatusKind.critical),
            StatusBadge(status: StatusKind.pending),
            StatusBadge(status: StatusKind.unknown),
            StatusBadge(status: StatusKind.recordedOnly),
            StatusBadge(status: StatusKind.skipped),
            StatusBadge(status: StatusKind.partial),
          ],
        ),
      );

      for (final label in [
        'Success',
        'Warning',
        'Critical',
        'Pending',
        'Unknown',
        'Recorded only',
        'Skipped',
        'Partial',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('parses raw backend status strings', (tester) async {
      await pump(
        tester,
        Wrap(
          children: [
            StatusBadge.fromString('complete'),
            StatusBadge.fromString('RECORDED_ONLY'),
            StatusBadge.fromString('not_found'),
            StatusBadge.fromString('total-nonsense'),
          ],
        ),
      );

      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Recorded only'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      // An unrecognised value must fall back to Unknown, never to a healthy state.
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Success'), findsNothing);
    });

    testWidgets('never colours an indeterminate state as success',
        (tester) async {
      await pump(tester, const StatusBadge(status: StatusKind.unknown));

      final colors = CsColors.of(tester.element(find.byType(StatusBadge)));
      final icon = tester.widget<Icon>(find.descendant(
        of: find.byType(StatusBadge),
        matching: find.byType(Icon),
      ));

      expect(icon.color, isNot(colors.success));
      expect(icon.color, colors.severityUnknown);
    });
  });

  group('SeverityBadge', () {
    testWidgets('renders the full severity ladder', (tester) async {
      await pump(
        tester,
        const Wrap(
          spacing: 8,
          children: [
            SeverityBadge(severity: Severity.low),
            SeverityBadge(severity: Severity.medium),
            SeverityBadge(severity: Severity.high),
            SeverityBadge(severity: Severity.critical),
            SeverityBadge(severity: Severity.unknown),
          ],
        ),
      );

      for (final label in ['Low', 'Medium', 'High', 'Critical', 'Unknown']) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
    });

    testWidgets('a null score renders Unknown rather than a healthy zero',
        (tester) async {
      await pump(tester, SeverityBadge.fromScore(null));

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Low'), findsNothing);
    });

    testWidgets('accepts mixed-case backend severity strings', (tester) async {
      await pump(
        tester,
        Wrap(
          children: [
            SeverityBadge.fromString('CRITICAL'),
            SeverityBadge.fromString('medium'),
            SeverityBadge.fromString('INFO'),
          ],
        ),
      );

      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    test('offers no success tone, so absence of data can never read as safe',
        () {
      expect(CsEmptyTone.values.map((t) => t.name), isNot(contains('success')));
    });

    testWidgets('uses factual default copy', (tester) async {
      await pump(tester, const EmptyState());

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('accepts specific copy and an action', (tester) async {
      await pump(
        tester,
        EmptyState(
          title: 'No alert data available',
          description: 'Alerts appear here once monitoring is active.',
          action: TextButton(onPressed: () {}, child: const Text('Start')),
        ),
      );

      expect(find.text('No alert data available'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('the neutral tone is not rendered in the success colour',
        (tester) async {
      await pump(tester, const EmptyState());

      final colors = CsColors.of(tester.element(find.byType(EmptyState)));
      final icon = tester.widget<Icon>(find.descendant(
        of: find.byType(EmptyState),
        matching: find.byType(Icon),
      ));

      expect(icon.color, isNot(colors.success));
      expect(icon.color, colors.textTertiary);
    });
  });

  group('ErrorState', () {
    testWidgets('shows human copy and no raw exception detail', (tester) async {
      await pump(tester, const ErrorState(message: ErrorState.genericMessage));

      expect(find.text('Unable to load data'), findsOneWidget);
      expect(find.text(ErrorState.genericMessage), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('retry is invoked from the button', (tester) async {
      var retries = 0;
      await pump(tester, ErrorState(onRetry: () => retries++));

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retries, 1);
    });
  });

  group('LoadingState', () {
    testWidgets('page variant shows the spinner and its message',
        (tester) async {
      await pump(
          tester, const LoadingState.page(message: 'Loading report data…'));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading report data…'), findsOneWidget);
    });

    testWidgets('inline variant renders its message', (tester) async {
      await pump(tester, const LoadingState.inline(message: 'Refreshing'));

      expect(find.text('Refreshing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('button variant does not inflate a button beyond a text label',
        (tester) async {
      await pump(
        tester,
        ElevatedButton(onPressed: () {}, child: const LoadingState.button()),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final spinnerHeight = tester.getSize(find.byType(ElevatedButton)).height;

      await pump(
        tester,
        ElevatedButton(onPressed: () {}, child: const Text('Scan')),
      );
      final labelHeight = tester.getSize(find.byType(ElevatedButton)).height;

      expect(spinnerHeight, lessThanOrEqualTo(labelHeight));
    });
  });

  group('MetricCard', () {
    testWidgets('renders an available value with its label', (tester) async {
      await pump(
        tester,
        const MetricCard(
          label: 'Packets analyzed',
          value: '1,284',
          subtitle: 'Current session',
        ),
      );

      expect(find.text('Packets analyzed'), findsOneWidget);
      expect(find.text('1,284'), findsOneWidget);
      expect(find.text('Current session'), findsOneWidget);
    });

    testWidgets('an unavailable metric reads N/A, never zero', (tester) async {
      await pump(
        tester,
        const MetricCard(
          label: 'Threat score',
          value: null,
          unavailableHint: 'Monitoring stopped',
        ),
      );

      expect(find.text('N/A'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('Monitoring stopped'), findsOneWidget);
    });

    testWidgets('honours a custom unavailable label', (tester) async {
      await pump(
        tester,
        const MetricCard(
          label: 'Blocked IPs',
          value: null,
          unavailableLabel: 'Unavailable',
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('shows a lifecycle badge when a status is supplied',
        (tester) async {
      await pump(
        tester,
        const MetricCard(
            label: 'Capture', value: '42', status: StatusKind.active),
      );

      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('SectionHeader and IconContainer', () {
    testWidgets('SectionHeader renders title, subtitle and action',
        (tester) async {
      await pump(
        tester,
        SectionHeader(
          title: 'Recent alerts',
          subtitle: 'Last 24 hours',
          action: TextButton(onPressed: () {}, child: const Text('View all')),
        ),
      );

      expect(find.text('Recent alerts'), findsOneWidget);
      expect(find.text('Last 24 hours'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
    });

    testWidgets('IconContainer sizes the chip and its glyph', (tester) async {
      await pump(
        tester,
        const Row(
          children: [
            IconContainer(icon: Icons.shield_outlined, size: CsIconSize.sm),
            IconContainer(icon: Icons.shield_outlined, size: CsIconSize.xl),
          ],
        ),
      );

      final sizes = tester
          .widgetList<IconContainer>(find.byType(IconContainer))
          .map((c) => c.size)
          .toList();
      expect(sizes, [CsIconSize.sm, CsIconSize.xl]);
      expect(tester.takeException(), isNull);
    });
  });

  group('Branding', () {
    testWidgets('the lockup renders the wordmark once', (tester) async {
      await pump(tester, const CyberSentinelLockup());

      expect(find.byType(CyberSentinelLogo), findsOneWidget);
      expect(find.textContaining('CyberSentinel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the mark-only variant omits the wordmark', (tester) async {
      await pump(
        tester,
        const CyberSentinelLockup(variant: CsLockupVariant.mark),
      );

      expect(find.textContaining('CyberSentinel'), findsNothing);
      expect(find.byType(CyberSentinelLogo), findsOneWidget);
    });

    testWidgets('the mark paints at rail and app-icon sizes without error',
        (tester) async {
      await pump(
        tester,
        const Row(
          children: [
            CyberSentinelLogo(size: 16),
            CyberSentinelLogo(size: 512),
          ],
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('narrow-width resilience', () {
    final cases = <String, Widget>{
      'AppCard': const AppCard(
        title: 'A very long card title that should wrap or ellipsize',
        subtitle: 'A subtitle that is also quite long indeed',
        child: Text('body'),
      ),
      'MetricCard': const MetricCard(
        label: 'Packets analyzed in the current session',
        value: '1,234,567',
        status: StatusKind.active,
      ),
      'EmptyState': const EmptyState(
        title: 'No alert data available',
        description: 'A fairly long description of why nothing is showing.',
      ),
      'ErrorState': const ErrorState(message: ErrorState.genericMessage),
      'SectionHeader': const SectionHeader(
        title: 'Recent alerts',
        subtitle: 'Last 24 hours',
      ),
      'badges': const Wrap(
        spacing: 8,
        children: [
          StatusBadge(status: StatusKind.recordedOnly),
          SeverityBadge(severity: Severity.critical),
        ],
      ),
    };

    final themes = <String, ThemeData Function()>{
      'dark': CsTheme.dark,
      'light': CsTheme.light,
    };

    for (final theme in themes.entries) {
      for (final entry in cases.entries) {
        testWidgets('${entry.key} does not overflow at 360px in ${theme.key}',
            (tester) async {
          tester.view.physicalSize = const Size(400, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pump(
            tester,
            SingleChildScrollView(child: entry.value),
            theme: theme.value(),
            width: 360,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
