import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../widgets/common/common.dart';

/// How the packets analyzed in the session on screen were classified.
///
/// Percentages live in the legend rather than inside the slices: the two were
/// duplicates, and only the legend can be read in both themes without putting
/// text on top of a saturated colour.
class PacketClassification extends StatelessWidget {
  const PacketClassification({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final colors = CsColors.of(context);
        final text = CsTypography.of(context);

        final total = provider.normalCount +
            provider.suspiciousCount +
            provider.maliciousCount +
            provider.unknownCount;

        final showSessionBreakdown =
            !provider.isCurrentSessionVisible && provider.lastSession != null;

        return AppCard(
          title: 'Analyzed Packet Distribution',
          subtitle: 'Classification of captured packets, not alert severity',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (total == 0)
                const EmptyState(
                  icon: LucideIcons.scanSearch,
                  title: 'No packets classified yet',
                  description:
                      'The distribution appears once the classifier has results.',
                  compact: true,
                )
              else ...[
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: [
                            _section(provider.normalCount, total,
                                colors.severityNormal),
                            _section(provider.suspiciousCount, total,
                                colors.severitySuspicious),
                            _section(provider.maliciousCount, total,
                                colors.severityMalicious),
                            _section(provider.unknownCount, total,
                                colors.severityUnknown),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            total.toString(),
                            style:
                                text.headline.copyWith(color: colors.textPrimary),
                          ),
                          Text(
                            'packets',
                            style: text.bodySmall
                                .copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CsSpacing.xl),
                _LegendRow(
                  label: 'Normal Traffic',
                  count: provider.normalCount,
                  total: total,
                  color: colors.severityNormal,
                ),
                const SizedBox(height: CsSpacing.md),
                _LegendRow(
                  label: 'Suspicious',
                  count: provider.suspiciousCount,
                  total: total,
                  color: colors.severitySuspicious,
                ),
                const SizedBox(height: CsSpacing.md),
                _LegendRow(
                  label: 'Malicious',
                  count: provider.maliciousCount,
                  total: total,
                  color: colors.severityMalicious,
                ),
                const SizedBox(height: CsSpacing.md),
                _LegendRow(
                  label: 'Unknown',
                  count: provider.unknownCount,
                  total: total,
                  color: colors.severityUnknown,
                ),
              ],
              if (showSessionBreakdown) ...[
                const SizedBox(height: CsSpacing.xl),
                Divider(
                  color: colors.border,
                  height: CsSpacing.lg,
                  thickness: 1,
                ),
                const SizedBox(height: CsSpacing.md),
                _CountRow(
                    label: 'Complete', count: provider.completePacketsCount),
                _CountRow(
                    label: 'Partial', count: provider.partialPacketsCount),
                _CountRow(label: 'Failed', count: provider.failedPacketsCount),
                _CountRow(
                    label: 'Deferred', count: provider.deferredPacketsCount),
                _CountRow(
                  label: 'Not analyzed',
                  count: provider.notAnalyzedPacketsCount,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static PieChartSectionData _section(int count, int total, Color color) {
    return PieChartSectionData(
      color: color,
      value: total == 0 ? 0 : (count / total) * 100,
      showTitle: false,
      radius: 50,
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final percentage = total == 0 ? 0.0 : (count / total) * 100;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: CsRadius.smallBorder,
          ),
        ),
        const SizedBox(width: CsSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.body.copyWith(color: colors.textSecondary),
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: text.body.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: text.bodyMedium.copyWith(color: colors.textSecondary)),
          Text(
            count.toString(),
            style: text.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
