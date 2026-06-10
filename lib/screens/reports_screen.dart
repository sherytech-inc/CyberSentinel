import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildThreatTrends(),
          const SizedBox(height: 24),
          _buildAttackTypes(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Security Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Weekly summary: Apr 06 - Apr 12, 2026',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.calendar, size: 16),
                label: const Text('Date Range'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Total Threats', '413', '+12%', AppTheme.error, true)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Threats Blocked', '364', '+8%', AppTheme.success, true)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Success Rate', '88%', '+3%', AppTheme.success, true)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Unique IPs', '247', '-5%', AppTheme.warning, false)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, String change, Color color, bool isIncrease) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(
                    isIncrease ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(change, style: TextStyle(fontSize: 14, color: color)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreatTrends() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Threat Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 45),
                      FlSpot(1, 52),
                      FlSpot(2, 38),
                      FlSpot(3, 67),
                      FlSpot(4, 72),
                      FlSpot(5, 58),
                      FlSpot(6, 81),
                    ],
                    isCurved: true,
                    color: AppTheme.error,
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 38),
                      FlSpot(1, 45),
                      FlSpot(2, 35),
                      FlSpot(3, 58),
                      FlSpot(4, 65),
                      FlSpot(5, 52),
                      FlSpot(6, 71),
                    ],
                    isCurved: true,
                    color: AppTheme.success,
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttackTypes() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Attack Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 342, color: AppTheme.primary, width: 32)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 289, color: AppTheme.primary, width: 32)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 234, color: AppTheme.primary, width: 32)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 187, color: AppTheme.primary, width: 32)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 156, color: AppTheme.primary, width: 32)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
