import 'dart:io';

import 'package:cybersentinel/providers/integrations_provider.dart';
import 'package:cybersentinel/providers/settings_provider.dart';
import 'package:cybersentinel/screens/settings_screen.dart';
import 'package:cybersentinel/widgets/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real provider calls the control-plane API on mount. Under `tester.pump`
/// real IO never completes, so the screen is pumped against a stub that reports
/// a settled, empty state instead.
class _IdleIntegrationsProvider extends IntegrationsProvider {
  @override
  Future<void> fetchIntegrations() async {}
}

Widget _app(ThemeData theme) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider<IntegrationsProvider>(
        create: (_) => _IdleIntegrationsProvider(),
      ),
    ],
    child: MaterialApp(
      theme: theme,
      home: const Scaffold(body: SettingsScreen()),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(
    WidgetTester tester,
    ThemeData theme, {
    double width = 1100,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(theme));
    await tester.pump();
  }

  for (final entry
      in {'dark': CsTheme.dark(), 'light': CsTheme.light()}.entries) {
    group('Settings in the ${entry.key} theme', () {
      testWidgets('renders every section without throwing', (tester) async {
        await pumpScreen(tester, entry.value);

        expect(tester.takeException(), isNull);
        expect(find.text('Monitoring'), findsOneWidget);
        expect(find.text('Integrations'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
        expect(find.text('Save Local Preferences'), findsOneWidget);
      });

      testWidgets(
          'section titles sit on the opposite end of the scale from the page',
          (tester) async {
        await pumpScreen(tester, entry.value);
        final context = tester.element(find.text('Monitoring'));
        final colors = CsColors.of(context);

        // The regression this guards: a screen left on the frozen dark palette
        // renders white titles on a white page in light mode.
        final title = tester.widget<Text>(find.text('Monitoring'));
        expect(title.style?.color, colors.textPrimary);
        expect(
          title.style!.color!.computeLuminance() > 0.5,
          colors.backgroundPrimary.computeLuminance() < 0.5,
        );
      });

      testWidgets('a settled integrations panel is honest about having no data',
          (tester) async {
        await pumpScreen(tester, entry.value);

        expect(find.text('No integration status available'), findsOneWidget);
        expect(find.text('Checking integrations'), findsNothing);
      });

      testWidgets('theme selection still drives SettingsProvider',
          (tester) async {
        await pumpScreen(tester, entry.value);
        final provider = Provider.of<SettingsProvider>(
          tester.element(find.byType(SettingsScreen)),
          listen: false,
        );

        await tester.ensureVisible(find.text('Light'));
        await tester.tap(find.text('Light'));
        await tester.pump();
        expect(provider.themeMode, ThemeMode.light);

        await tester.ensureVisible(find.text('Dark'));
        await tester.tap(find.text('Dark'));
        await tester.pump();
        expect(provider.themeMode, ThemeMode.dark);
      });

      testWidgets('the chosen theme is marked by a glyph, not colour alone',
          (tester) async {
        await pumpScreen(tester, entry.value);

        await tester.ensureVisible(find.text('Light'));
        await tester.tap(find.text('Light'));
        await tester.pump();

        final selected = find.ancestor(
          of: find.text('Light'),
          matching: find.byType(Semantics),
        );
        expect(
          tester.widget<Semantics>(selected.first).properties.selected,
          isTrue,
        );
        expect(find.byIcon(LucideIcons.circleCheck), findsWidgets);
      });

      testWidgets('the honest "not available" notice survives the migration',
          (tester) async {
        await pumpScreen(tester, entry.value);

        expect(
          find.textContaining('not available in this build'),
          findsOneWidget,
        );
      });

      testWidgets('no overflow at 360px', (tester) async {
        await pumpScreen(tester, entry.value, width: 360);

        expect(tester.takeException(), isNull);
      });
    });
  }

  test('the migrated screen no longer reads the frozen legacy palette', () {
    // Guards against a partial migration leaving AppTheme constants behind,
    // which is what makes light mode unreadable.
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();
    expect(source, isNot(contains('AppTheme.')));
    expect(source, isNot(contains('Colors.white')));
  });
}
