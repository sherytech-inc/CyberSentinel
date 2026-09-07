import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_typography.dart';
import 'icon_container.dart';

/// Tone of an empty state.
///
/// There is deliberately no `success` tone. An absence of data is not evidence
/// of safety, so an empty state may never be rendered green.
enum CsEmptyTone { neutral, info, warning }

/// One shared empty-state presentation for the whole application.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.title = 'No data available',
    this.description,
    this.action,
    this.tone = CsEmptyTone.neutral,
    this.compact = false,
  });

  final IconData? icon;

  /// Factual wording. Prefer "No alert data available" over anything that
  /// implies the system is safe.
  final String title;

  final String? description;
  final Widget? action;
  final CsEmptyTone tone;

  /// Tighter vertical rhythm for use inside tables and side panels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    final (Color accent, IconData glyph) = switch (tone) {
      CsEmptyTone.neutral => (
          colors.textTertiary,
          icon ?? LucideIcons.database
        ),
      CsEmptyTone.info => (colors.info, icon ?? LucideIcons.clock),
      CsEmptyTone.warning => (
          colors.warning,
          icon ?? LucideIcons.triangleAlert
        ),
    };

    final vertical = compact ? CsSpacing.xl : CsSpacing.xxxl;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: CsSpacing.xl,
          vertical: vertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconContainer(
              icon: glyph,
              color: accent,
              background: CsColors.tint(accent, alpha: 0.08),
              size: compact ? CsIconSize.md : CsIconSize.xl,
            ),
            SizedBox(height: compact ? CsSpacing.md : CsSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (compact ? text.sectionTitle : text.title)
                  .copyWith(color: colors.textSecondary),
            ),
            if (description != null) ...[
              const SizedBox(height: CsSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: text.bodySmall.copyWith(color: colors.textTertiary),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: CsSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
