import 'package:flutter/material.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_typography.dart';
import 'icon_container.dart';

/// Consistent section heading used above card groups, tables and panels.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.dense = false,
    this.showDivider = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Trailing control — a filter, a refresh button, an export menu.
  final Widget? action;

  final bool dense;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final gap = dense ? CsSpacing.sm : CsSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconContainer(
                icon: icon!,
                size: CsIconSize.sm,
                color: colors.textSecondary,
                background: colors.surfaceHover,
              ),
              const SizedBox(width: CsSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: (dense ? text.sectionTitle : text.title)
                        .copyWith(color: colors.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style:
                          text.bodySmall.copyWith(color: colors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: CsSpacing.sm),
              action!,
            ],
          ],
        ),
        if (showDivider) ...[
          SizedBox(height: gap),
          Divider(color: colors.border, height: 1, thickness: 1),
        ],
      ],
    );
  }
}
