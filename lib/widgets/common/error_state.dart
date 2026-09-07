import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_typography.dart';
import 'icon_container.dart';

/// One shared error presentation.
///
/// [message] must be human-readable copy written for an analyst. Never pass a
/// raw exception, stack trace, provider response body or internal URL — the
/// type has no field for one, by design.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Unable to load data',
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.compact = false,
  });

  /// Fallback copy for any failure where a more specific message is not
  /// available. Deliberately free of implementation detail.
  static const String genericMessage =
      'Unable to load security data. Please try again.';

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final vertical = compact ? CsSpacing.lg : CsSpacing.xxl;

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
              icon: LucideIcons.circleX,
              color: colors.error,
              background: colors.errorBackground,
              size: compact ? CsIconSize.md : CsIconSize.xl,
            ),
            SizedBox(height: compact ? CsSpacing.md : CsSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (compact ? text.sectionTitle : text.title)
                  .copyWith(color: colors.textPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: CsSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: text.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: CsSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                // Styled explicitly rather than through a global button theme,
                // which would restyle every unmigrated screen in the app.
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.borderStrong),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CsSpacing.lg,
                    vertical: CsSpacing.sm,
                  ),
                  minimumSize: const Size(0, CsHitTarget.comfortable),
                  textStyle: text.label,
                  shape: const RoundedRectangleBorder(
                    borderRadius: CsRadius.mediumBorder,
                  ),
                ),
                icon: Icon(LucideIcons.refreshCw,
                    size: 15, color: colors.primary),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
