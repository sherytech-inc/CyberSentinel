import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class PacketClassification extends StatelessWidget {
  const PacketClassification({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final total = provider.normalCount + provider.suspiciousCount + provider.maliciousCount;
        double normalPct = 100.0;
        double suspiciousPct = 0.0;
        double maliciousPct = 0.0;

        if (total > 0) {
          normalPct = (provider.normalCount / total) * 100;
          suspiciousPct = (provider.suspiciousCount / total) * 100;
          maliciousPct = (provider.maliciousCount / total) * 100;
        } else {
          normalPct = 0.0;
        }

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
              const Text(
                'Analyzed Packet Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Classification of captured packets, not alert severity',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                height: 200,
                child: Center(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: total == 0
                          ? [
                              PieChartSectionData(
                                color: AppTheme.borderPrimary,
                                value: 100,
                                title: 'No Data',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ]
                          : [
                              if (normalPct > 0)
                                PieChartSectionData(
                                  color: AppTheme.success,
                                  value: normalPct,
                                  showTitle: normalPct > 5 || total > 0 && normalPct == 100,
                                  title: '${normalPct.toStringAsFixed(1)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              if (suspiciousPct > 0)
                                PieChartSectionData(
                                  color: AppTheme.warning,
                                  value: suspiciousPct,
                                  showTitle: suspiciousPct > 5 || total > 0 && suspiciousPct == 100,
                                  title: '${suspiciousPct.toStringAsFixed(1)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              if (maliciousPct > 0)
                                PieChartSectionData(
                                  color: AppTheme.error,
                                  value: maliciousPct,
                                  showTitle: maliciousPct > 5 || total > 0 && maliciousPct == 100,
                                  title: '${maliciousPct.toStringAsFixed(1)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              _buildLegendItem('Normal Traffic', '${normalPct.toStringAsFixed(1)}%', AppTheme.success),
              const SizedBox(height: AppTheme.spacing12),
              _buildLegendItem('Suspicious', '${suspiciousPct.toStringAsFixed(1)}%', AppTheme.warning),
              const SizedBox(height: AppTheme.spacing12),
              _buildLegendItem('Malicious', '${maliciousPct.toStringAsFixed(1)}%', AppTheme.error),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
