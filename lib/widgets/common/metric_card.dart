import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_semantics.dart';
import '../../core/theme/cs_typography.dart';
import 'app_card.dart';
import 'badge.dart';
import 'icon_container.dart';
import 'status_badge.dart';

/// Direction of a metric's movement between samples.
enum MetricTrend { up, down, flat }

/// Enterprise metric/KPI card.
///
/// Replaces the duplicated KPI implementations in the dashboard widgets and the
/// threat response screen.
///
/// A null [value] means the metric is **unavailable**, not zero. It renders as
/// [unavailableLabel] in a muted tone so that missing data can never be
/// mistaken for a healthy result.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.footnote,
    this.trend,
    this.trendLabel,
    this.status,
    this.statusLabel,
    this.onTap,
    this.dense = false,
    this.unavailableLabel = 'N/A',
    this.unavailableHint,
  });

  /// Metric name, e.g. "Packets analyzed".
  final String label;

  /// Pre-formatted readout. Pass null when the value could not be obtained.
  final String? value;

  final IconData? icon;
  final Color? iconColor;

  /// Short qualifier under the value, e.g. "Last completed session".
  final String? subtitle;

  /// Fine print at the bottom of the card.
  final String? footnote;

  final MetricTrend? trend;
  final String? trendLabel;

  /// Optional lifecycle badge — use for capture/monitoring state.
  final StatusKind? status;
  final String? statusLabel;

  final VoidCallback? onTap;
  final bool dense;

  final String unavailableLabel;

  /// Extra copy shown only when [value] is null, e.g. "Monitoring stopped".
  final String? unavailableHint;

  bool get _available => value != null;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    final valueColor = _available ? colors.textPrimary : colors.textTertiary;

    return AppCard(
      onTap: onTap,
      dense: dense,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodySmall.copyWith(color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status != null) ...[
                const SizedBox(width: CsSpacing.sm),
                StatusBadge(
                  status: status!,
                  label: statusLabel,
                  size: CsBadgeSize.sm,
                ),
              ],
              if (icon != null) ...[
                const SizedBox(width: CsSpacing.sm),
                IconContainer(
                  icon: icon!,
                  color: _available
                      ? (iconColor ?? colors.primary)
                      : colors.textTertiary,
                  size: CsIconSize.sm,
                ),
              ],
            ],
          ),
          const SizedBox(height: CsSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _available ? value! : unavailableLabel,
                  style: (dense ? text.title : text.metric)
                      .copyWith(color: valueColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: CsSpacing.sm),
                _Trend(
                    text: text,
                    color: colors.textTertiary,
                    trend: trend!,
                    label: trendLabel),
              ],
            ],
          ),
          if (!_available && unavailableHint != null) ...[
            const SizedBox(height: CsSpacing.xs),
            Text(
              unavailableHint!,
              style: text.caption.copyWith(color: colors.textTertiary),
            ),
          ] else if (subtitle != null) ...[
            const SizedBox(height: CsSpacing.xs),
            Text(
              subtitle!,
              style: text.caption.copyWith(color: colors.textTertiary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: CsSpacing.md),
            Text(
              footnote!,
              style: text.caption.copyWith(color: colors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Trend extends StatelessWidget {
  const _Trend({
    required this.text,
    required this.color,
    required this.trend,
    this.label,
  });

  final CsTextStyles text;
  final Color color;
  final MetricTrend trend;
  final String? label;

  IconData get _icon {
    switch (trend) {
      case MetricTrend.up:
        return LucideIcons.trendingUp;
      case MetricTrend.down:
        return LucideIcons.trendingDown;
      case MetricTrend.flat:
        return LucideIcons.minus;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Direction is intentionally not colour-coded: in a security product a
    // rising count is not automatically good. Callers convey favourability
    // through wording rather than through the trend glyph.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 14, color: color),
        if (label != null) ...[
          const SizedBox(width: CsSpacing.xs),
          Text(label!, style: text.caption.copyWith(color: color)),
        ],
      ],
    );
  }
}
