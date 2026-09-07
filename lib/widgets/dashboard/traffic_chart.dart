import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../widgets/common/common.dart';

/// One plotted line in the traffic chart.
///
/// Keeping the label next to the colour means the tooltip can look a series up
/// by index instead of comparing rendered colours for equality.
class _TrafficSeries {
  const _TrafficSeries(this.label, this.color, this.valueOf);

  final String label;
  final Color color;
  final int Function(TrafficData point) valueOf;
}

class TrafficChart extends StatelessWidget {
  const TrafficChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final colors = CsColors.of(context);
        final text = CsTypography.of(context);
        final showCurrentSession = provider.isCurrentSessionVisible;

        final normal = _TrafficSeries(
            'Normal', colors.severityNormal, (point) => point.normal);
        final suspicious = _TrafficSeries(
            'Suspicious', colors.severitySuspicious, (point) => point.suspicious);
        final malicious = _TrafficSeries(
            'Malicious', colors.severityMalicious, (point) => point.malicious);
        final pending = _TrafficSeries(
          showCurrentSession ? 'Pending' : 'Not analyzed',
          colors.severityPending,
          (point) => point.pending,
        );

        // Drawing order is preserved from the original so the dominant
        // "normal" line still paints on top at crossings.
        final bars = <_TrafficSeries>[pending, malicious, suspicious, normal];
        final legend = <_TrafficSeries>[normal, suspicious, malicious, pending];

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showCurrentSession
                              ? 'Real-Time Network Traffic'
                              : 'Last Session Overview',
                          style: text.title.copyWith(color: colors.textPrimary),
                        ),
                        const SizedBox(height: CsSpacing.xs),
                        Text(
                          showCurrentSession
                              ? provider.isStopping
                                  ? 'Finalizing current-session analysis'
                                  : 'Packets per update'
                              : 'Final classification and analysis distribution',
                          style: text.bodySmall
                              .copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: CsSpacing.lg),
                  Flexible(
                    flex: 3,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: CsSpacing.lg,
                      runSpacing: CsSpacing.sm,
                      children: [
                        for (final series in legend)
                          _LegendItem(series: series, text: text, colors: colors),
                      ],
                    ),
                  ),
                ],
              ),
              if (!showCurrentSession && provider.lastSession != null)
                Padding(
                  padding: const EdgeInsets.only(top: CsSpacing.lg),
                  child: Wrap(
                    spacing: CsSpacing.xl,
                    runSpacing: CsSpacing.sm,
                    children: [
                      _SessionMetric(
                          label: 'Captured',
                          value: provider.capturedPacketsCount.toString()),
                      _SessionMetric(
                          label: 'Analyzed',
                          value: provider.analyzedPacketsCount.toString()),
                      _SessionMetric(
                        label: 'Analysis Completion',
                        value:
                            '${(provider.analysisCompletion * 100).toStringAsFixed(1)}%',
                      ),
                      _SessionMetric(
                        label: 'Highest Severity',
                        badge: SeverityBadge.fromString(
                          provider.lastSession?.highestSeverity,
                          size: CsBadgeSize.sm,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: CsSpacing.xl),
              SizedBox(
                height: 350,
                child: _buildPlot(
                  provider: provider,
                  showCurrentSession: showCurrentSession,
                  bars: bars,
                  colors: colors,
                  text: text,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlot({
    required DashboardProvider provider,
    required bool showCurrentSession,
    required List<_TrafficSeries> bars,
    required CsColors colors,
    required CsTextStyles text,
  }) {
    if (!showCurrentSession && provider.lastSession == null) {
      return const EmptyState(
        icon: LucideIcons.chartSpline,
        title: 'No completed session data available',
        description: 'Traffic history appears after a capture session ends.',
        compact: true,
      );
    }

    final data = provider.trafficData;
    if (data.length < 2) {
      return EmptyState(
        icon: LucideIcons.activity,
        title: showCurrentSession
            ? 'Monitoring active — collecting traffic'
            : 'Waiting for live packet capture',
        description: showCurrentSession
            ? 'The chart starts once more than one update has arrived.'
            : null,
        compact: true,
      );
    }

    double maxVal = 10.0;
    for (final point in data) {
      for (final series in bars) {
        maxVal = math.max(maxVal, series.valueOf(point).toDouble());
      }
    }
    final double maxY = maxVal * 1.2;
    final double leftInterval =
        (maxY / 5).roundToDouble().clamp(1.0, double.infinity);

    final int dataLength = data.length;
    final double maxXVal = dataLength > 1 ? (dataLength - 1).toDouble() : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: leftInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.border,
            strokeWidth: 1,
            dashArray: const [3, 3],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: dataLength <= 8 ? 1 : 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dataLength) return const SizedBox();
                if (dataLength > 8 && index % 6 != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index].time,
                    style: text.caption.copyWith(color: colors.textTertiary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: leftInterval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: text.caption.copyWith(color: colors.textTertiary),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: colors.surfaceElevated,
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return [];

              final int index = touchedSpots.first.x.toInt();
              final time =
                  index >= 0 && index < dataLength ? data[index].time : '';

              return touchedSpots.map((spot) {
                final series = bars[spot.barIndex];
                final valueStyle = TextStyle(
                  color: series.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                final label = '${series.label}: ${spot.y.toInt()}';

                if (spot != touchedSpots.first) {
                  return LineTooltipItem(label, valueStyle);
                }
                return LineTooltipItem(
                  '$time\n',
                  TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [TextSpan(text: label, style: valueStyle)],
                );
              }).toList();
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxXVal,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          for (final series in bars)
            LineChartBarData(
              spots: [
                for (var i = 0; i < dataLength; i++)
                  FlSpot(i.toDouble(), series.valueOf(data[i]).toDouble()),
              ],
              isCurved: false,
              color: series.color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.series,
    required this.text,
    required this.colors,
  });

  final _TrafficSeries series;
  final CsTextStyles text;
  final CsColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: series.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: CsSpacing.sm),
        Text(
          series.label,
          style: text.bodySmall.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

/// Compact inset tile. Deliberately not an [AppCard]: it sits inside one, and a
/// card nested in a card would double the border and padding rhythm.
class _SessionMetric extends StatelessWidget {
  const _SessionMetric({required this.label, this.value, this.badge});

  final String label;

  /// Numeric readout. Mutually exclusive with [badge].
  final String? value;

  /// Used instead of [value] when the tile holds a severity rather than a count.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(CsSpacing.lg),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        border: Border.all(color: colors.border),
        borderRadius: CsRadius.mediumBorder,
      ),
      child: Column(
        children: [
          if (badge != null)
            badge!
          else
            Text(
              value ?? 'N/A',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.headline.copyWith(
                color: value == null ? colors.textTertiary : colors.textPrimary,
              ),
            ),
          const SizedBox(height: CsSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: text.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
