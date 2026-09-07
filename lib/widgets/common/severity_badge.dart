import 'package:flutter/material.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_semantics.dart';
import 'badge.dart';

/// Standardised security-severity badge.
///
/// One colour mapping for the entire product, replacing the three divergent
/// severity palettes currently implemented inline in the packet tracing,
/// threat response and alerts widgets.
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({
    super.key,
    required this.severity,
    this.label,
    this.size = CsBadgeSize.md,
    this.showIcon = true,
    this.tooltip,
  });

  /// Accepts the raw severity strings the backend already sends
  /// (`'CRITICAL'`, `'medium'`, `'INFO'`, ...). Unrecognised values resolve to
  /// [Severity.unknown].
  factory SeverityBadge.fromString(
    String? raw, {
    Key? key,
    String? label,
    CsBadgeSize size = CsBadgeSize.md,
    bool showIcon = true,
    String? tooltip,
  }) {
    return SeverityBadge(
      key: key,
      severity: CsSemantics.parseSeverity(raw),
      label: label,
      size: size,
      showIcon: showIcon,
      tooltip: tooltip,
    );
  }

  /// Builds from a 0–100 threat score. A null score yields
  /// [Severity.unknown] and must never render as a healthy zero.
  factory SeverityBadge.fromScore(
    num? score, {
    Key? key,
    String? label,
    CsBadgeSize size = CsBadgeSize.md,
    bool showIcon = true,
    String? tooltip,
  }) {
    return SeverityBadge(
      key: key,
      severity: CsSemantics.severityFromScore(score),
      label: label,
      size: size,
      showIcon: showIcon,
      tooltip: tooltip,
    );
  }

  final Severity severity;
  final String? label;
  final CsBadgeSize size;
  final bool showIcon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SemanticBadge(
      state: CsSemantics.severity(severity, CsColors.of(context)),
      label: label,
      size: size,
      showIcon: showIcon,
      tooltip: tooltip,
    );
  }
}
