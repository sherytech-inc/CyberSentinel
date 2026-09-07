import 'package:flutter/material.dart';

/// Spacing rhythm. Values match the legacy `AppTheme.spacing*` constants so a
/// migrated screen keeps its existing layout.
class CsSpacing {
  CsSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Default inner padding for cards and panels.
  static const EdgeInsets card = EdgeInsets.all(xl);

  /// Tighter inner padding for dense panels and list rows.
  static const EdgeInsets cardCompact = EdgeInsets.all(lg);
}

/// Corner radii. Restrained on purpose — CyberSentinel is a desktop console,
/// not a mobile app, so nothing here approaches a bubble shape.
class CsRadius {
  CsRadius._();

  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;
  static const double xl = 16;
  static const double pill = 999;

  static const BorderRadius smallBorder =
      BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumBorder =
      BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeBorder =
      BorderRadius.all(Radius.circular(large));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillBorder =
      BorderRadius.all(Radius.circular(pill));
}

/// Conceptual window classes. Named for layout capacity rather than for a
/// device, so the shell can decide between a rail, a drawer and a full sidebar.
enum CsWindowSize { compact, medium, expanded }

/// Breakpoints and the layout metrics derived from them.
///
/// These are independent of the legacy `AppTheme.isMobile`/`isDesktop` helpers,
/// which existing screens still use; do not change those in this phase.
class CsBreakpoints {
  CsBreakpoints._();

  static const double compact = 768;
  static const double expanded = 1200;

  /// Full sidebar width, matching the shell's current 240px.
  static const double sidebarExpanded = 240;

  /// Icon-only rail used at medium widths.
  static const double sidebarRail = 68;

  static CsWindowSize windowSizeOf(double width) {
    if (width < compact) {
      return CsWindowSize.compact;
    }
    if (width < expanded) {
      return CsWindowSize.medium;
    }
    return CsWindowSize.expanded;
  }

  static CsWindowSize of(BuildContext context) =>
      windowSizeOf(MediaQuery.sizeOf(context).width);

  /// Sidebar width appropriate for [size]. At compact widths the sidebar should
  /// move into a drawer, so the inline width is zero.
  static double sidebarWidthFor(CsWindowSize size) {
    switch (size) {
      case CsWindowSize.compact:
        return 0;
      case CsWindowSize.medium:
        return sidebarRail;
      case CsWindowSize.expanded:
        return sidebarExpanded;
    }
  }

  /// Number of grid columns for metric/KPI rows at a given width.
  static int metricColumnsFor(CsWindowSize size) {
    switch (size) {
      case CsWindowSize.compact:
        return 1;
      case CsWindowSize.medium:
        return 2;
      case CsWindowSize.expanded:
        return 4;
    }
  }
}

/// Minimum interactive sizes, kept generous for pointer and keyboard use.
class CsHitTarget {
  CsHitTarget._();

  static const double minimum = 32;
  static const double comfortable = 40;
}
