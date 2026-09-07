import 'package:flutter/material.dart';

/// Semantic type scale for CyberSentinel.
///
/// Sizes stay close to the values the existing screens already use (body 14,
/// metric 28, eyebrow 11) so that migrating a screen to the design system does
/// not silently change its visual rhythm.
///
/// Resolve with `CsTypography.of(context)` so the ambient font family (Inter,
/// supplied by `app.dart`) is inherited rather than overridden.
class CsTypography {
  CsTypography._();

  /// Font family supplied by `app.dart` via `GoogleFonts.interTextTheme`.
  static const String fontFamily = 'Inter';

  static final Map<String?, CsTextStyles> _cache = <String?, CsTextStyles>{};

  /// The scale for an explicit [family]. Used when building [ThemeData], where
  /// no `BuildContext` exists yet.
  static CsTextStyles forFamily(String? family) =>
      _cache.putIfAbsent(family, () => CsTextStyles._(family));

  static CsTextStyles of(BuildContext context) =>
      forFamily(Theme.of(context).textTheme.bodyMedium?.fontFamily);
}

/// The resolved type scale for one font family.
@immutable
class CsTextStyles {
  const CsTextStyles._(this._family);

  final String? _family;

  TextStyle _style({
    required double size,
    required FontWeight weight,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: _family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Largest style, reserved for page-level numbers and hero metrics.
  TextStyle get display => _style(
      size: 32, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.5);

  /// Page title.
  TextStyle get headline => _style(
      size: 22, weight: FontWeight.w600, height: 1.25, letterSpacing: -0.2);

  /// Card or panel title.
  TextStyle get title => _style(size: 16, weight: FontWeight.w600, height: 1.3);

  /// Sub-section heading inside a card.
  TextStyle get sectionTitle =>
      _style(size: 15, weight: FontWeight.w600, height: 1.35);

  /// Primary reading text.
  TextStyle get body => _style(size: 14, weight: FontWeight.w400, height: 1.5);

  /// Secondary reading text and dense table cells.
  TextStyle get bodyMedium =>
      _style(size: 13, weight: FontWeight.w400, height: 1.45);

  /// Fine print, timestamps, helper text.
  TextStyle get bodySmall =>
      _style(size: 12, weight: FontWeight.w400, height: 1.45);

  /// Emphasised inline label, button text.
  TextStyle get label => _style(size: 13, weight: FontWeight.w500, height: 1.4);

  /// Small emphasised label, badge text.
  TextStyle get labelMedium =>
      _style(size: 12, weight: FontWeight.w500, height: 1.4);

  /// Smallest text; use sparingly.
  TextStyle get caption =>
      _style(size: 11, weight: FontWeight.w400, height: 1.4);

  /// Large numeric readout for KPI and metric cards.
  TextStyle get metric => _style(
      size: 28, weight: FontWeight.w700, height: 1.15, letterSpacing: -0.5);

  /// Uppercase micro-label. Pair with `toUpperCase()` at the call site.
  TextStyle get eyebrow => _style(
      size: 11, weight: FontWeight.w600, height: 1.3, letterSpacing: 1.0);
}
