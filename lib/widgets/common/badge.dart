import 'package:flutter/material.dart';

import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_semantics.dart';
import '../../core/theme/cs_typography.dart';

/// Badge density.
enum CsBadgeSize { sm, md }

/// The single badge primitive for the whole application.
///
/// [StatusBadge] and [SeverityBadge] are thin wrappers over this; screens that
/// need a custom label can use it directly. Meaning is always carried by
/// icon + text + colour together, never colour alone.
class SemanticBadge extends StatelessWidget {
  const SemanticBadge({
    super.key,
    required this.state,
    this.label,
    this.size = CsBadgeSize.md,
    this.showIcon = true,
    this.tooltip,
  });

  final SemanticState state;

  /// Overrides [SemanticState.label] when the caller has more specific wording.
  final String? label;

  final CsBadgeSize size;
  final bool showIcon;

  /// When set, the badge is wrapped in a tooltip carrying the same text, which
  /// keeps icon-only or truncated usages accessible.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final text = CsTypography.of(context);
    final displayLabel = label ?? state.label;

    final iconSize = size == CsBadgeSize.sm ? 12.0 : 14.0;
    final labelStyle =
        (size == CsBadgeSize.sm ? text.caption : text.labelMedium)
            .copyWith(color: state.foreground);
    final padding = size == CsBadgeSize.sm
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
        : const EdgeInsets.symmetric(
            horizontal: CsSpacing.sm, vertical: CsSpacing.xs);

    final badge = Semantics(
      container: true,
      label: displayLabel,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: state.background,
          borderRadius: CsRadius.pillBorder,
          border: Border.all(color: state.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(state.icon, size: iconSize, color: state.foreground),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                displayLabel,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    if (tooltip == null) {
      return badge;
    }
    return Tooltip(message: tooltip!, child: badge);
  }
}
