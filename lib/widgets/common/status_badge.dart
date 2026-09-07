import 'package:flutter/material.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_semantics.dart';
import 'badge.dart';

/// Standardised lifecycle/availability badge.
///
/// Keeps `active`, `pending`, `partial`, `failed`, `recorded only` and
/// `skipped` visually distinct — these must never be collapsed into a single
/// "ok" presentation.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.size = CsBadgeSize.md,
    this.showIcon = true,
    this.tooltip,
  });

  /// Accepts the raw status strings the backend already sends
  /// (`'complete'`, `'RECORDED_ONLY'`, `'not_found'`, ...). Unrecognised values
  /// resolve to [StatusKind.unknown] rather than to a healthy state.
  factory StatusBadge.fromString(
    String? raw, {
    Key? key,
    String? label,
    CsBadgeSize size = CsBadgeSize.md,
    bool showIcon = true,
    String? tooltip,
  }) {
    return StatusBadge(
      key: key,
      status: CsSemantics.parseStatus(raw),
      label: label,
      size: size,
      showIcon: showIcon,
      tooltip: tooltip,
    );
  }

  final StatusKind status;
  final String? label;
  final CsBadgeSize size;
  final bool showIcon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SemanticBadge(
      state: CsSemantics.status(status, CsColors.of(context)),
      label: label,
      size: size,
      showIcon: showIcon,
      tooltip: tooltip,
    );
  }
}
