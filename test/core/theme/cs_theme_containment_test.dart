import 'package:cybersentinel/core/theme/app_theme.dart';
import 'package:cybersentinel/widgets/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rebuilds the theme exactly as `app.dart` did before the design system
/// existed. This is the reference an unmigrated screen renders against.
///
/// The original passed a GoogleFonts [TextTheme]; that is omitted on both sides
/// because font loading is asynchronous and `CsTheme` falls back to the same
/// platform text theme when none is injected, so the comparison stays fair.
ThemeData _legacyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? AppTheme.bgPrimary : Colors.white,
    textTheme:
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light())
        .copyWith(
      primary: AppTheme.primary,
      secondary: AppTheme.secondary,
      surface: isDark ? AppTheme.bgPrimary : Colors.white,
    ),
  );
}

ThemeData _csTheme(Brightness brightness) =>
    brightness == Brightness.dark ? CsTheme.dark() : CsTheme.light();

/// Measures [probe] as it actually lays out under [theme].
///
/// A bare Material widget with no inline style is the canary here: it renders
/// entirely from the ambient theme, so any global component-theme override
/// shows up as a different size or shape. Screens that pass explicit styles
/// would hide the regression, which is how it shipped the first time.
Future<Size> _measure(
  WidgetTester tester,
  ThemeData theme,
  Widget probe,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: SizedBox(width: 200, child: probe))),
    ),
  );
  return tester.getSize(find.byWidget(probe));
}

void main() {
  group('theme containment: unmigrated screens render as they did before', () {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      final label = brightness.name;

      testWidgets('$label: Icon keeps its default box', (tester) async {
        expect(
          await _measure(tester, _csTheme(brightness), const Icon(Icons.add)),
          await _measure(
              tester, _legacyTheme(brightness), const Icon(Icons.add)),
        );
      });

      testWidgets('$label: Divider keeps its vertical space', (tester) async {
        expect(
          await _measure(tester, _csTheme(brightness), const Divider()),
          await _measure(tester, _legacyTheme(brightness), const Divider()),
        );
      });

      testWidgets('$label: Card keeps its margin and elevation',
          (tester) async {
        final cs = _csTheme(brightness);
        final legacy = _legacyTheme(brightness);
        expect(
          await _measure(
            tester,
            cs,
            const Card(child: SizedBox(width: 100, height: 50)),
          ),
          await _measure(
            tester,
            legacy,
            const Card(child: SizedBox(width: 100, height: 50)),
          ),
        );
        expect(cs.cardTheme.elevation, legacy.cardTheme.elevation);
        expect(cs.cardTheme.shape, legacy.cardTheme.shape);
      });

      testWidgets('$label: buttons keep their shape and metrics',
          (tester) async {
        final cs = _csTheme(brightness);
        final legacy = _legacyTheme(brightness);
        expect(
          await _measure(
            tester,
            cs,
            OutlinedButton(onPressed: () {}, child: const Text('Go')),
          ),
          await _measure(
            tester,
            legacy,
            OutlinedButton(onPressed: () {}, child: const Text('Go')),
          ),
        );
        // Geometry alone cannot distinguish a pill from a rounded rectangle,
        // which is the exact change that hit the Settings save button.
        const states = <WidgetState>{};
        expect(
          cs.outlinedButtonTheme.style?.shape?.resolve(states),
          legacy.outlinedButtonTheme.style?.shape?.resolve(states),
        );
        expect(
          cs.outlinedButtonTheme.style?.textStyle?.resolve(states),
          legacy.outlinedButtonTheme.style?.textStyle?.resolve(states),
        );
        expect(
          cs.elevatedButtonTheme.style?.shape?.resolve(states),
          legacy.elevatedButtonTheme.style?.shape?.resolve(states),
        );
        expect(
          cs.textButtonTheme.style?.shape?.resolve(states),
          legacy.textButtonTheme.style?.shape?.resolve(states),
        );
        expect(
          cs.iconButtonTheme.style?.shape?.resolve(states),
          legacy.iconButtonTheme.style?.shape?.resolve(states),
        );
      });

      test('$label: text fields keep their default border', () {
        final cs = _csTheme(brightness);
        final legacy = _legacyTheme(brightness);
        expect(
            cs.inputDecorationTheme.border, legacy.inputDecorationTheme.border);
        expect(
          cs.inputDecorationTheme.enabledBorder,
          legacy.inputDecorationTheme.enabledBorder,
        );
        expect(
            cs.inputDecorationTheme.filled, legacy.inputDecorationTheme.filled);
      });

      test('$label: overlays and chrome keep Material defaults', () {
        // Each of these was overridden once already and each one reached a real
        // screen: the shell popup menu, app-wide scrollbars, tooltips, dialogs
        // and snackbars.
        final cs = _csTheme(brightness);
        final legacy = _legacyTheme(brightness);
        expect(cs.iconTheme, legacy.iconTheme);
        expect(cs.dividerTheme, legacy.dividerTheme);
        expect(cs.dialogTheme, legacy.dialogTheme);
        expect(cs.popupMenuTheme, legacy.popupMenuTheme);
        expect(cs.tooltipTheme, legacy.tooltipTheme);
        expect(cs.snackBarTheme, legacy.snackBarTheme);
        expect(cs.scrollbarTheme, legacy.scrollbarTheme);
        expect(cs.progressIndicatorTheme, legacy.progressIndicatorTheme);
        expect(cs.textSelectionTheme, legacy.textSelectionTheme);
      });

      test('$label: colour scheme, scaffold and text match the legacy values',
          () {
        final cs = _csTheme(brightness);
        final legacy = _legacyTheme(brightness);
        expect(cs.colorScheme, legacy.colorScheme);
        expect(cs.scaffoldBackgroundColor, legacy.scaffoldBackgroundColor);
        expect(cs.textTheme, legacy.textTheme);
      });
    }
  });

  group('the design system still works after containment', () {
    test('semantic tokens are still registered on both themes', () {
      for (final theme in [CsTheme.dark(), CsTheme.light()]) {
        final colors = theme.extension<CsColors>();
        expect(colors, isNotNull);
        expect(colors!.backgroundPrimary, isNot(Colors.transparent));
        expect(colors.textPrimary, isNot(Colors.transparent));
        expect(colors.primary, isNot(Colors.transparent));
      }
    });

    testWidgets('ErrorState styles its own retry button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: CsTheme.dark(),
          home: Scaffold(
            body:
                ErrorState(message: 'Test copy', onRetry: () => tapped = true),
          ),
        ),
      );

      // The button no longer inherits a global theme, so it must carry its own
      // shape — otherwise removing the overrides would flatten the design
      // system along with the regression.
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(
        button.style?.shape?.resolve(const <WidgetState>{}),
        isA<RoundedRectangleBorder>(),
      );

      await tester.tap(find.byType(OutlinedButton));
      expect(tapped, isTrue);
    });
  });
}
