import 'package:flutter/material.dart';

/// Semantic colour tokens for CyberSentinel.
///
/// Components must depend on these tokens rather than on raw palette values, so
/// that the same widget renders correctly under both the dark and light themes.
/// Access through `CsColors.of(context)`.
///
/// The legacy [AppTheme] statics remain untouched for the ~1000 existing call
/// sites; new and migrated code should use this extension.
@immutable
class CsColors extends ThemeExtension<CsColors> {
  const CsColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.surfacePressed,
    required this.border,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryForeground,
    required this.success,
    required this.successBackground,
    required this.warning,
    required this.warningBackground,
    required this.error,
    required this.errorBackground,
    required this.info,
    required this.infoBackground,
    required this.severityNormal,
    required this.severitySuspicious,
    required this.severityMalicious,
    required this.severityUnknown,
    required this.severityPending,
    required this.focusRing,
    required this.overlay,
    required this.shadowSubtle,
    required this.shadowMedium,
    required this.shadowStrong,
  });

  /// Modern-minimal dark theme — neutral charcoal surfaces, one blue accent.
  /// Aligned with the GitHub-dark scale rather than the legacy navy/cyan.
  factory CsColors.dark() => const CsColors(
        backgroundPrimary: Color(0xFF0D1117),
        backgroundSecondary: Color(0xFF010409),
        backgroundTertiary: Color(0xFF161B22),
        surface: Color(0xFF161B22),
        surfaceElevated: Color(0xFF1C2128),
        surfaceHover: Color(0xFF21262D),
        surfacePressed: Color(0xFF2D333B),
        border: Color(0xFF30363D),
        borderSubtle: Color(0xFF21262D),
        borderStrong: Color(0xFF3D444D),
        textPrimary: Color(0xFFE6EDF3),
        textSecondary: Color(0xFF9198A1),
        textTertiary: Color(0xFF6E7681),
        textDisabled: Color(0xFF484F58),
        primary: Color(0xFF58A6FF),
        primaryHover: Color(0xFF79B8FF),
        primaryPressed: Color(0xFF388BFD),
        primaryForeground: Color(0xFF0D1117),
        success: Color(0xFF3FB950),
        successBackground: Color(0xFF12261E),
        warning: Color(0xFFD29922),
        warningBackground: Color(0xFF261C06),
        error: Color(0xFFF85149),
        errorBackground: Color(0xFF2A1116),
        info: Color(0xFF58A6FF),
        infoBackground: Color(0xFF111F38),
        severityNormal: Color(0xFF3FB950),
        severitySuspicious: Color(0xFFD29922),
        severityMalicious: Color(0xFFF85149),
        severityUnknown: Color(0xFF6E7681),
        severityPending: Color(0xFF58A6FF),
        focusRing: Color(0xFF58A6FF),
        overlay: Color(0xB3010409),
        shadowSubtle: <BoxShadow>[],
        shadowMedium: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        shadowStrong: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      );

  /// Modern-minimal light theme — soft grey page, white cards, one blue accent.
  /// Aligned with the GitHub-light scale; every foreground clears the page
  /// contrast requirements on its own.
  factory CsColors.light() => const CsColors(
        backgroundPrimary: Color(0xFFF6F8FA),
        backgroundSecondary: Color(0xFFFFFFFF),
        backgroundTertiary: Color(0xFFEFF2F5),
        surface: Color(0xFFFFFFFF),
        surfaceElevated: Color(0xFFFFFFFF),
        surfaceHover: Color(0xFFF2F4F7),
        surfacePressed: Color(0xFFE8ECEF),
        border: Color(0xFFD1D9E0),
        borderSubtle: Color(0xFFE6EAEE),
        borderStrong: Color(0xFF9AA4AF),
        textPrimary: Color(0xFF1F2328),
        textSecondary: Color(0xFF59636E),
        textTertiary: Color(0xFF8C959F),
        textDisabled: Color(0xFFB3BCC4),
        primary: Color(0xFF0969DA),
        primaryHover: Color(0xFF0860CA),
        primaryPressed: Color(0xFF0757BA),
        primaryForeground: Color(0xFFFFFFFF),
        success: Color(0xFF1A7F37),
        successBackground: Color(0xFFE6F4EA),
        warning: Color(0xFF9A6700),
        warningBackground: Color(0xFFFDF3E0),
        error: Color(0xFFD1242F),
        errorBackground: Color(0xFFFCEBE9),
        info: Color(0xFF0969DA),
        infoBackground: Color(0xFFE8F1FD),
        severityNormal: Color(0xFF1A7F37),
        severitySuspicious: Color(0xFF9A6700),
        severityMalicious: Color(0xFFD1242F),
        severityUnknown: Color(0xFF8C959F),
        severityPending: Color(0xFF0969DA),
        focusRing: Color(0xFF0969DA),
        overlay: Color(0x661F2328),
        shadowSubtle: [
          BoxShadow(
            color: Color(0x0F1F2328),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
        shadowMedium: [
          BoxShadow(
            color: Color(0x141F2328),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        shadowStrong: [
          BoxShadow(
            color: Color(0x1F1F2328),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      );

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundTertiary;

  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHover;
  final Color surfacePressed;

  final Color border;
  final Color borderSubtle;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryForeground;

  final Color success;
  final Color successBackground;
  final Color warning;
  final Color warningBackground;
  final Color error;
  final Color errorBackground;
  final Color info;
  final Color infoBackground;

  /// Threat-classification colours. These carry meaning: green is reserved for
  /// genuinely healthy data, never for "no data yet".
  final Color severityNormal;
  final Color severitySuspicious;
  final Color severityMalicious;
  final Color severityUnknown;
  final Color severityPending;

  final Color focusRing;
  final Color overlay;

  /// Dark mode relies on border contrast, so [shadowSubtle] is empty there.
  final List<BoxShadow> shadowSubtle;
  final List<BoxShadow> shadowMedium;
  final List<BoxShadow> shadowStrong;

  /// Resolves the tokens for [context], falling back to the dark palette when a
  /// widget is rendered outside a CyberSentinel theme (for example in a bare
  /// unit test).
  static CsColors of(BuildContext context) {
    final colors = Theme.of(context).extension<CsColors>();
    return colors ?? CsColors.dark();
  }

  /// A translucent wash of [base], used for icon chips and inline badges.
  static Color tint(Color base, {double alpha = 0.12}) =>
      base.withValues(alpha: alpha);

  /// A translucent outline of [base], used for badge and chip borders.
  static Color hairline(Color base, {double alpha = 0.28}) =>
      base.withValues(alpha: alpha);

  @override
  CsColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundTertiary,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHover,
    Color? surfacePressed,
    Color? border,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? primary,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryForeground,
    Color? success,
    Color? successBackground,
    Color? warning,
    Color? warningBackground,
    Color? error,
    Color? errorBackground,
    Color? info,
    Color? infoBackground,
    Color? severityNormal,
    Color? severitySuspicious,
    Color? severityMalicious,
    Color? severityUnknown,
    Color? severityPending,
    Color? focusRing,
    Color? overlay,
    List<BoxShadow>? shadowSubtle,
    List<BoxShadow>? shadowMedium,
    List<BoxShadow>? shadowStrong,
  }) {
    return CsColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundTertiary: backgroundTertiary ?? this.backgroundTertiary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      success: success ?? this.success,
      successBackground: successBackground ?? this.successBackground,
      warning: warning ?? this.warning,
      warningBackground: warningBackground ?? this.warningBackground,
      error: error ?? this.error,
      errorBackground: errorBackground ?? this.errorBackground,
      info: info ?? this.info,
      infoBackground: infoBackground ?? this.infoBackground,
      severityNormal: severityNormal ?? this.severityNormal,
      severitySuspicious: severitySuspicious ?? this.severitySuspicious,
      severityMalicious: severityMalicious ?? this.severityMalicious,
      severityUnknown: severityUnknown ?? this.severityUnknown,
      severityPending: severityPending ?? this.severityPending,
      focusRing: focusRing ?? this.focusRing,
      overlay: overlay ?? this.overlay,
      shadowSubtle: shadowSubtle ?? this.shadowSubtle,
      shadowMedium: shadowMedium ?? this.shadowMedium,
      shadowStrong: shadowStrong ?? this.shadowStrong,
    );
  }

  @override
  CsColors lerp(covariant ThemeExtension<CsColors>? other, double t) {
    if (other is! CsColors) {
      return this;
    }
    return CsColors(
      backgroundPrimary:
          Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      backgroundTertiary:
          Color.lerp(backgroundTertiary, other.backgroundTertiary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      severityNormal: Color.lerp(severityNormal, other.severityNormal, t)!,
      severitySuspicious:
          Color.lerp(severitySuspicious, other.severitySuspicious, t)!,
      severityMalicious:
          Color.lerp(severityMalicious, other.severityMalicious, t)!,
      severityUnknown: Color.lerp(severityUnknown, other.severityUnknown, t)!,
      severityPending: Color.lerp(severityPending, other.severityPending, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shadowSubtle:
          BoxShadow.lerpList(shadowSubtle, other.shadowSubtle, t) ?? const [],
      shadowMedium:
          BoxShadow.lerpList(shadowMedium, other.shadowMedium, t) ?? const [],
      shadowStrong:
          BoxShadow.lerpList(shadowStrong, other.shadowStrong, t) ?? const [],
    );
  }
}
