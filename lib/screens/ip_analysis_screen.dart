import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../providers/ip_analysis_provider.dart';

class IPAnalysisScreen extends StatelessWidget {
  const IPAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IPAnalysisProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  _buildSearchBar(provider),
                  // Show validation error if present
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorBanner(provider.errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  if (provider.ipInfo != null) ...[
                    _buildInfoCards(provider),
                    const SizedBox(height: 24),
                    _buildMapAndInfo(provider),
                    const SizedBox(height: 24),
                    _buildActivityChart(provider),
                  ] else if (provider.errorMessage == null)
                    _buildEmptyState(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Error Banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleX, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(color: AppTheme.error, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(IPAnalysisProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter IP address to analyze (e.g., 192.168.1.1)',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: AppTheme.borderPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: provider.setSearchQuery,
              // Allow submitting by pressing Enter
              onSubmitted: (_) => provider.analyzeIP(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: provider.analyzeIP,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  // ── Info Cards ─────────────────────────────────────────────────────────────

  Widget _buildInfoCards(IPAnalysisProvider provider) {
    final ip = provider.ipInfo!;
    return Row(
      children: [
        Expanded(
            child: _buildInfoCard(
          'Location',
          ip.location,
          ip.country,
          LucideIcons.mapPin,
          AppTheme.info,
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildInfoCard(
          'ISP',
          ip.isp,
          'Internet Service Provider',
          LucideIcons.globe,
          Colors.purple,
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildReputationCard(ip.reputation)),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReputationCard(int reputation) {
    final color = reputation >= 70
        ? AppTheme.success
        : reputation >= 40
            ? AppTheme.warning
            : AppTheme.error;
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.shield, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Reputation Score',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$reputation/100',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.borderPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: reputation / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map + IP Info ──────────────────────────────────────────────────────────

  Widget _buildMapAndInfo(IPAnalysisProvider provider) {
    final ip = provider.ipInfo!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildMapPlaceholder(ip.location)),
        const SizedBox(width: 16),
        Expanded(child: _buildIPInfo(ip)),
      ],
    );
  }

  Widget _buildMapPlaceholder(String location) {
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
          const Text(
            'Geographic Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.borderPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.mapPin,
                        color: AppTheme.primary, size: 64),
                    const SizedBox(height: 12),
                    const Text('Map View',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    Text(
                      location,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIPInfo(dynamic ip) {
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
          const Text(
            'IP Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('IP Address', ip.ip),
          _buildInfoRow('Country Code', ip.country),
          _buildInfoRow('Threat Level', ip.threatLevel.name.toUpperCase()),
          _buildInfoRow('Last Seen', '2 minutes ago'),
          _buildInfoRow('Total Requests', '1,234'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.borderPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Activity Chart ─────────────────────────────────────────────────────────

  Widget _buildActivityChart(IPAnalysisProvider provider) {
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
          Row(
            children: const [
              Icon(LucideIcons.activity, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Activity History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: provider.activityData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value.requests.toDouble(),
                            ))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.primary,
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

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Icon(LucideIcons.search, size: 64, color: AppTheme.textTertiary),
          SizedBox(height: 16),
          Text(
            'No IP Analyzed Yet',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Enter an IP address above to view detailed analysis',
            style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
