import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'cs_colors.dart';
import 'cs_typography.dart';

/// Assembles the CyberSentinel [ThemeData] for both brightnesses.
///
/// This class deliberately does **not** configure Material component themes.
/// Roughly a thousand unmigrated call sites render against Material's own
/// defaults, and `Card`, `Divider`, `Icon`, `TextField` and the four button
/// types all fall through to them. Overriding any component theme here silently
/// restyles screens that have not been migrated — icons shrink, dividers
/// collapse, pills become rounded rectangles.
///
/// Semantic styling therefore lives in the [CsColors] extension and is opt-in
/// per widget: a component that wants the design system reads
/// `CsColors.of(context)` and styles itself. Component themes are introduced
/// only as screens are migrated, at which point there is nothing left to break.
///
/// Font loading is not done here. `app.dart` supplies the Inter [TextTheme] so
/// that the design system stays free of asynchronous font work and can be
/// exercised directly in tests.
class CsTheme {
  CsTheme._();

  static ThemeData dark({TextTheme? textTheme}) =>
      _build(CsColors.dark(), Brightness.dark, textTheme);

  static ThemeData light({TextTheme? textTheme}) =>
      _build(CsColors.light(), Brightness.light, textTheme);

  static CsColors colorsOf(BuildContext context) => CsColors.of(context);

  static CsTextStyles textOf(BuildContext context) => CsTypography.of(context);

  static ThemeData _build(
    CsColors colors,
    Brightness brightness,
    TextTheme? textTheme,
  ) {
    final isDark = brightness == Brightness.dark;

    // Pinned to the exact values app.dart used before the design system
    // existed, read through the frozen legacy facade so the two cannot drift.
    // `CsColors` carries the accessible light-mode palette for new components;
    // the Material layer keeps the legacy one until screens are migrated.
    final colorScheme =
        (isDark ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(
      primary: AppTheme.primary,
      secondary: AppTheme.secondary,
      surface: isDark ? AppTheme.bgPrimary : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppTheme.bgPrimary : Colors.white,
      textTheme: textTheme ??
          (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
