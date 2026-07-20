import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
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
                        'Packets per update',
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
                height: 350,
                child: () {
                  if (provider.trafficData.length < 2) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for live packet capture.\nDemo Mode alerts do not generate live traffic visualization.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  double maxVal = 10.0;
                  for (var d in provider.trafficData) {
                    final double val = math.max(d.normal.toDouble(), math.max(d.suspicious.toDouble(), d.malicious.toDouble()));
                    if (val > maxVal) {
                      maxVal = val;
                    }
                  }
                  final double maxY = maxVal * 1.2;
                  final double leftInterval = (maxY / 5).roundToDouble().clamp(1.0, double.infinity);
                  
                  final int dataLength = provider.trafficData.length;
                  final double maxXVal = dataLength > 1 ? (dataLength - 1).toDouble() : 1.0;

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: leftInterval,
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
                            interval: dataLength <= 8 ? 1 : 5,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dataLength) {
                                if (dataLength <= 8 || value.toInt() % 6 == 0) {
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
                            interval: leftInterval,
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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: AppTheme.bgSecondary,
                          getTooltipItems: (touchedSpots) {
                            if (touchedSpots.isEmpty) return [];
                            
                            final int index = touchedSpots.first.x.toInt();
                            final time = index >= 0 && index < provider.trafficData.length 
                                ? provider.trafficData[index].time 
                                : '';
                                
                            return touchedSpots.map((spot) {
                              final textStyle = TextStyle(
                                color: spot.bar.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              
                              String label = '';
                              if (spot.bar.color == AppTheme.success) label = 'Normal: ';
                              else if (spot.bar.color == AppTheme.warning) label = 'Suspicious: ';
                              else if (spot.bar.color == AppTheme.error) label = 'Malicious: ';

                              if (spot == touchedSpots.first) {
                                return LineTooltipItem(
                                  '$time\n',
                                  const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                  children: [
                                    TextSpan(text: '$label${spot.y.toInt()}', style: textStyle),
                                  ],
                                );
                              }
                              return LineTooltipItem('$label${spot.y.toInt()}', textStyle);
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

                      LineChartBarData(
                        spots: provider.trafficData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.malicious.toDouble(),
                                ))
                            .toList(),
                        isCurved: false,
                        color: AppTheme.error,
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
                        isCurved: false,
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
                                  e.value.normal.toDouble(),
                                ))
                            .toList(),
                        isCurved: false,
                        color: AppTheme.success,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                );
              }(),
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
