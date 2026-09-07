import 'package:cybersentinel/core/theme/app_theme.dart';
import 'package:cybersentinel/core/theme/cs_colors.dart';
import 'package:cybersentinel/core/theme/cs_layout.dart';
import 'package:cybersentinel/core/theme/cs_semantics.dart';
import 'package:cybersentinel/core/theme/cs_theme.dart';
import 'package:cybersentinel/core/theme/cs_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ThemeData darkTheme() => CsTheme.dark();
  ThemeData lightTheme() => CsTheme.light();

  CsColors colorsIn(ThemeData theme) =>
      theme.extension<CsColors>() ??
      (throw StateError('CsColors not registered'));

  group('theme construction', () {
    test('dark theme builds and registers semantic tokens', () {
      final theme = darkTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<CsColors>(), isNotNull);
      // The Material scaffold stays on the legacy navy so unmigrated screens
      // are untouched; the migrated shell paints the token colour itself.
      expect(theme.scaffoldBackgroundColor, AppTheme.bgPrimary);
      expect(colorsIn(theme).backgroundPrimary, const Color(0xFF0D1117));
      expect(
        colorsIn(theme).backgroundPrimary,
        isNot(theme.scaffoldBackgroundColor),
      );
    });

    test('light theme builds and registers semantic tokens', () {
      final theme = lightTheme();
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<CsColors>(), isNotNull);
      // The scaffold is pinned to the legacy white, NOT to the token's
      // 0xFFF6F7F9. Every screen still hardcodes dark AppTheme colours, so
      // driving the Material layer from the tokens would restyle unmigrated
      // screens — that is the regression this phase is not allowed to cause.
      // The token stays available through the extension for new components.
      expect(theme.scaffoldBackgroundColor, Colors.white);
      expect(
        colorsIn(theme).backgroundPrimary,
        isNot(theme.scaffoldBackgroundColor),
      );
    });

    test('light theme text is dark on a light page, never white-on-white', () {
      final colors = colorsIn(lightTheme());

      expect(colors.backgroundPrimary.computeLuminance(), greaterThan(0.5));
      expect(colors.textPrimary.computeLuminance(), lessThan(0.3));
      expect(colors.textSecondary.computeLuminance(), lessThan(0.5));

      // The regression this guards against: AppTheme.textPrimary is pure white
      // and leaked into the light theme, rendering text invisible.
      expect(colors.textPrimary, isNot(const Color(0xFFFFFFFF)));
    });

    test('dark theme text is light on a dark page', () {
      final colors = colorsIn(darkTheme());
      expect(colors.backgroundPrimary.computeLuminance(), lessThan(0.2));
      expect(colors.textPrimary.computeLuminance(), greaterThan(0.7));
    });

    test('the two themes do not share a palette', () {
      final dark = colorsIn(darkTheme());
      final light = colorsIn(lightTheme());

      expect(dark.backgroundPrimary, isNot(light.backgroundPrimary));
      expect(dark.textPrimary, isNot(light.textPrimary));
      expect(dark.surface, isNot(light.surface));
      expect(dark.border, isNot(light.border));
    });

    test('every semantic token is non-transparent in both themes', () {
      for (final theme in [darkTheme(), lightTheme()]) {
        final colors = colorsIn(theme);
        final tokens = <String, Color>{
          'backgroundPrimary': colors.backgroundPrimary,
          'backgroundSecondary': colors.backgroundSecondary,
          'backgroundTertiary': colors.backgroundTertiary,
          'surface': colors.surface,
          'surfaceElevated': colors.surfaceElevated,
          'surfaceHover': colors.surfaceHover,
          'surfacePressed': colors.surfacePressed,
          'border': colors.border,
          'borderSubtle': colors.borderSubtle,
          'borderStrong': colors.borderStrong,
          'textPrimary': colors.textPrimary,
          'textSecondary': colors.textSecondary,
          'textTertiary': colors.textTertiary,
          'textDisabled': colors.textDisabled,
          'primary': colors.primary,
          'primaryForeground': colors.primaryForeground,
          'success': colors.success,
          'warning': colors.warning,
          'error': colors.error,
          'info': colors.info,
          'severityNormal': colors.severityNormal,
          'severitySuspicious': colors.severitySuspicious,
          'severityMalicious': colors.severityMalicious,
          'severityUnknown': colors.severityUnknown,
          'severityPending': colors.severityPending,
          'focusRing': colors.focusRing,
        };

        tokens.forEach((name, color) {
          expect(color, isNot(Colors.transparent),
              reason: '$name is transparent');
          expect(color.a, greaterThan(0), reason: '$name is fully transparent');
        });
      }
    });

    test('primary accent clears a usable contrast ratio on its own surface',
        () {
      for (final theme in [darkTheme(), lightTheme()]) {
        final colors = colorsIn(theme);
        final ratio = _contrastRatio(colors.primary, colors.backgroundPrimary);
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: 'primary accent contrast is $ratio');
      }
    });
  });

  group('theme switching', () {
    testWidgets('switching between dark, light and system does not throw',
        (tester) async {
      ThemeMode mode = ThemeMode.dark;
      late StateSetter setOuterState;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setOuterState = setState;
            return MaterialApp(
              themeMode: mode,
              theme: lightTheme(),
              darkTheme: darkTheme(),
              home: Builder(
                builder: (context) {
                  final colors = CsColors.of(context);
                  return Text(colors.textPrimary.toString(),
                      textDirection: TextDirection.ltr);
                },
              ),
            );
          },
        ),
      );

      final darkText = tester.widget<Text>(find.byType(Text)).data;

      setOuterState(() => mode = ThemeMode.light);
      await tester.pumpAndSettle();
      final lightText = tester.widget<Text>(find.byType(Text)).data;
      expect(lightText, isNot(darkText));

      setOuterState(() => mode = ThemeMode.system);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CsColors.of resolves the active theme inside a widget tree',
        (tester) async {
      late CsColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme(),
          home: Builder(
            builder: (context) {
              resolved = CsColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.textPrimary, colorsIn(lightTheme()).textPrimary);
    });

    test('CsColors.lerp interpolates between themes', () {
      final dark = colorsIn(darkTheme());
      final light = colorsIn(lightTheme());

      final mid = dark.lerp(light, 0.5);
      expect(mid, isA<CsColors>());
      expect(mid.backgroundPrimary, isNot(dark.backgroundPrimary));
      expect(mid.backgroundPrimary, isNot(light.backgroundPrimary));
    });
  });

  group('typography', () {
    test('the scale is ordered and uses distinct sizes', () {
      final text = CsTypography.forFamily(CsTypography.fontFamily);
      final sizes = <double>[
        text.display.fontSize!,
        text.headline.fontSize!,
        text.title.fontSize!,
        text.sectionTitle.fontSize!,
        text.body.fontSize!,
        text.bodyMedium.fontSize!,
        text.bodySmall.fontSize!,
        text.caption.fontSize!,
      ];

      for (var i = 0; i < sizes.length - 1; i++) {
        expect(sizes[i], greaterThan(sizes[i + 1]),
            reason: 'type scale is not descending at index $i');
      }
      expect(text.metric.fontSize, 28);
      expect(text.eyebrow.letterSpacing, greaterThan(0.5));
    });

    test('the resolved scale carries the ambient font family', () {
      final text = CsTypography.forFamily('Inter');
      expect(text.body.fontFamily, 'Inter');
    });
  });

  group('responsive foundation', () {
    test('window classes map from width', () {
      expect(CsBreakpoints.windowSizeOf(462), CsWindowSize.compact);
      expect(CsBreakpoints.windowSizeOf(600), CsWindowSize.compact);
      expect(CsBreakpoints.windowSizeOf(768), CsWindowSize.medium);
      expect(CsBreakpoints.windowSizeOf(1024), CsWindowSize.medium);
      expect(CsBreakpoints.windowSizeOf(1440), CsWindowSize.expanded);
    });

    test('the sidebar collapses rather than overflowing at compact widths', () {
      expect(CsBreakpoints.sidebarWidthFor(CsWindowSize.compact), lessThan(1));
      expect(CsBreakpoints.sidebarWidthFor(CsWindowSize.medium),
          CsBreakpoints.sidebarRail);
      expect(CsBreakpoints.sidebarWidthFor(CsWindowSize.expanded),
          CsBreakpoints.sidebarExpanded);
    });
  });

  group('semantic colour mapping', () {
    test('absent data is never presented as a healthy result', () {
      for (final colors in [colorsIn(darkTheme()), colorsIn(lightTheme())]) {
        final unknown = CsSemantics.severity(Severity.unknown, colors);
        final pending = CsSemantics.status(StatusKind.pending, colors);
        final skipped = CsSemantics.status(StatusKind.skipped, colors);

        for (final state in [unknown, pending, skipped]) {
          expect(state.indeterminate, isTrue);
          expect(state.foreground, isNot(colors.success));
          expect(state.foreground, isNot(colors.severityNormal));
        }
      }
    });

    test('malicious and suspicious states stay visually distinct', () {
      final colors = colorsIn(darkTheme());
      final malicious =
          CsSemantics.classification(ThreatClassification.malicious, colors);
      final suspicious =
          CsSemantics.classification(ThreatClassification.suspicious, colors);
      final normal =
          CsSemantics.classification(ThreatClassification.normal, colors);

      expect(malicious.foreground, isNot(suspicious.foreground));
      expect(suspicious.foreground, isNot(normal.foreground));
      expect(malicious.foreground, colors.error);
      expect(suspicious.foreground, colors.warning);
      expect(normal.foreground, colors.success);
    });

    test('recorded-only firewall actions are not shown as enforced', () {
      final colors = colorsIn(darkTheme());
      final recorded = CsSemantics.status(StatusKind.recordedOnly, colors);
      final success = CsSemantics.status(StatusKind.success, colors);

      expect(recorded.label, 'Recorded only');
      expect(recorded.foreground, isNot(success.foreground));
      expect(recorded.icon, isNot(success.icon));
    });

    test('a null threat score resolves to unknown, not to low', () {
      expect(CsSemantics.severityFromScore(null), Severity.unknown);
      expect(CsSemantics.severityFromScore(0), Severity.low);
      expect(CsSemantics.severityFromScore(45), Severity.medium);
      expect(CsSemantics.severityFromScore(85), Severity.critical);
    });

    test('backend status strings parse into the right kind', () {
      expect(CsSemantics.parseStatus('complete'), StatusKind.complete);
      expect(CsSemantics.parseStatus('RECORDED_ONLY'), StatusKind.recordedOnly);
      expect(CsSemantics.parseStatus('not_found'), StatusKind.failed);
      expect(CsSemantics.parseStatus('skipped'), StatusKind.skipped);
      expect(CsSemantics.parseStatus(null), StatusKind.unknown);
      expect(CsSemantics.parseStatus('nonsense'), StatusKind.unknown);
    });

    test('backend severity strings parse case-insensitively', () {
      expect(CsSemantics.parseSeverity('CRITICAL'), Severity.critical);
      expect(CsSemantics.parseSeverity('medium'), Severity.medium);
      expect(CsSemantics.parseSeverity('INFO'), Severity.low);
      expect(CsSemantics.parseSeverity(null), Severity.unknown);
    });

    test('every semantic state carries a label and an icon, not colour alone',
        () {
      final colors = colorsIn(darkTheme());

      final states = <SemanticState>[
        for (final s in Severity.values) CsSemantics.severity(s, colors),
        for (final c in ThreatClassification.values)
          CsSemantics.classification(c, colors),
        for (final k in StatusKind.values) CsSemantics.status(k, colors),
      ];

      for (final state in states) {
        expect(state.label.trim(), isNotEmpty);
        expect(state.icon, isNotNull);
      }
    });
  });
}

/// WCAG relative contrast ratio between two colours.
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
