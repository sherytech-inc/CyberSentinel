import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class TrafficChart extends StatelessWidget {
  const TrafficChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border.all(color: AppTheme.borderPrimary),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Real-Time Network Traffic',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Packets per 5-minute interval',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildLegendItem('Normal', AppTheme.success),
                      const SizedBox(width: AppTheme.spacing16),
                      _buildLegendItem('Suspicious', AppTheme.warning),
                      const SizedBox(width: AppTheme.spacing16),
                      _buildLegendItem('Malicious', AppTheme.error),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1000,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppTheme.borderPrimary,
                          strokeWidth: 1,
                          dashArray: [3, 3],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < provider.trafficData.length) {
                              if (value.toInt() % 6 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    provider.trafficData[value.toInt()].time,
                                    style: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: 2000,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: provider.trafficData.length.toDouble() - 1,
                    minY: 0,
                    maxY: 10000,
                    lineBarsData: [
                      LineChartBarData(
                        spots: provider.trafficData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.normal.toDouble(),
                                ))
                            .toList(),
                        isCurved: true,
                        color: AppTheme.success,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: provider.trafficData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.suspicious.toDouble(),
                                ))
                            .toList(),
                        isCurved: true,
                        color: AppTheme.warning,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: provider.trafficData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.malicious.toDouble(),
                                ))
                            .toList(),
                        isCurved: true,
                        color: AppTheme.error,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
