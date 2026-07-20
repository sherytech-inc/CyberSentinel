import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../providers/reports_provider.dart';
import '../services/api_service.dart';
import '../../utils/date_parser.dart';
import '../providers/metrics_provider.dart';
import '../models/global_metrics.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReportsProvider>();
      provider.fetchDashboard();
      provider.fetchSnapshots();
    });
  }

  void _downloadFile(String type, String timeRange) async {
    final url = ApiService.getReportingDownloadUrl(type, timeRange);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch export URL: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.dashboardData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = Map<String, dynamic>.from(provider.dashboardData ?? {});
        final kpis = Map<String, dynamic>.from(data['kpis'] ?? {});
        final trends = data['threat_trends'] as List<dynamic>? ?? [];
        final severityData = data['severity_distribution'] as List<dynamic>? ?? [];
        final topThreats = data['top_threat_types'] as List<dynamic>? ?? [];
        final attackers = data['top_attackers'] as List<dynamic>? ?? [];
        final responseAnalytics = Map<String, dynamic>.from(data['response_analytics'] ?? {});

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              const SizedBox(height: 24),
              _buildExecutiveSummary(),
              const SizedBox(height: 24),
              _buildKPICards(),
              const SizedBox(height: 24),
              _buildThreatTrends(trends),
              const SizedBox(height: 24),
              _buildBreakdownCharts(severityData, topThreats),
              const SizedBox(height: 24),
              _buildTopAttackers(attackers),
              const SizedBox(height: 24),
              _buildResponseTimeline(responseAnalytics),
              const SizedBox(height: 24),
              _buildExportPanel(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ReportsProvider provider) {
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
            children: [
              const Text(
                'Reports & Intelligence Center',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '24h', label: Text('24h')),
                  ButtonSegment(value: '7d', label: Text('7d')),
                  ButtonSegment(value: '30d', label: Text('30d')),
                ],
                selected: {provider.timeRange},
                onSelectionChanged: (Set<String> newSelection) {
                  provider.setTimeRange(newSelection.first);
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppTheme.bgSecondary,
                  foregroundColor: AppTheme.textSecondary,
                  selectedForegroundColor: AppTheme.primary,
                  selectedBackgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: provider.isSnapshotGenerating ? null : () => provider.createSnapshot(),
            icon: provider.isSnapshotGenerating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.camera, size: 16),
            label: const Text('Generate Snapshot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, _) {
        final timeRange = reportsProvider.timeRange;
        final kpis = reportsProvider.kpis;
        
        final total = kpis?.totalThreats ?? 0;
        final critical = kpis?.criticalThreats ?? 0;
        final responses = kpis?.responseActions ?? 0;
        final recorded = kpis?.recordedBlocks ?? 0;
        final osEnforced = kpis?.osEnforcedBlocks ?? 0;

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
                'Executive Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              if (total == 0)
                const Text(
                  'No security incidents were detected during the selected period.\n\nCyberSentinel is actively monitoring network activity.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                )
              else
                Text(
                  'During the selected time range ($timeRange), CyberSentinel detected a total of $total threats, out of which $critical were identified as critical incidents. The system automatically executed $responses response actions, recording $recorded block actions with $osEnforced currently enforced at the OS firewall level.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICards() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, _) {
        final kpis = reportsProvider.kpis;
        return Row(
          children: [
            Expanded(child: _buildKPICard('Total Threats', '${kpis?.totalThreats ?? 0}', LucideIcons.shieldAlert, AppTheme.error)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard('Response Actions', '${kpis?.responseActions ?? 0}', LucideIcons.activity, AppTheme.info)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard('Recorded Blocks', '${kpis?.recordedBlocks ?? 0}', LucideIcons.shieldX, AppTheme.warning)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard('OS-Enforced Blocks', '${kpis?.osEnforcedBlocks ?? 0}', LucideIcons.shieldCheck, AppTheme.success)),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatTrends(List<dynamic> trends) {
    if (trends.isEmpty) {
      return const SizedBox();
    }

    final spots = trends.asMap().entries.map((e) {
      final val = (e.value['count'] as num).toDouble();
      return FlSpot(e.key.toDouble(), val);
    }).toList();

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
            'Threat Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minX: trends.length == 1 ? -1 : null,
                maxX: trends.length == 1 ? 1 : null,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= trends.length) return const SizedBox();
                        final timeStr = trends[idx]['time'].toString();
                        final dt = DateParser.safeParse(timeStr);
                        final shortTime = dt != null
                            ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                            : '??:??';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(shortTime, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.error,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.error.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCharts(List<dynamic> severityData, List<dynamic> threatTypes) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              border: Border.all(color: AppTheme.borderPrimary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Severity Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: severityData.isEmpty ? 
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.shieldCheck, color: AppTheme.success, size: 32),
                          SizedBox(height: 12),
                          Text("No threat data available.", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      )
                    ) : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: severityData.where((e) => (e['count'] as num).toDouble() > 0).map((e) {
                        final sev = e['severity'].toString().toUpperCase();
                        final count = (e['count'] as num).toDouble();
                        Color c = AppTheme.info;
                        if (sev == 'CRITICAL') { c = AppTheme.error; }
                        else if (sev == 'HIGH') { c = Colors.orange; }
                        else if (sev == 'MEDIUM') { c = AppTheme.warning; }
                        return PieChartSectionData(
                          color: c,
                          value: count,
                          title: '${count.toInt()}',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: severityData.map((e) {
                    final sev = e['severity'].toString();
                    Color c = AppTheme.info;
                    if (sev.toUpperCase() == 'CRITICAL') { c = AppTheme.error; }
                    else if (sev.toUpperCase() == 'HIGH') { c = Colors.orange; }
                    else if (sev.toUpperCase() == 'MEDIUM') { c = AppTheme.warning; }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 12, color: c),
                        const SizedBox(width: 4),
                        Text(sev, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              border: Border.all(color: AppTheme.borderPrimary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Threat Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 240,
                  child: threatTypes.isEmpty ? 
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.shieldCheck, color: AppTheme.success, size: 32),
                          SizedBox(height: 12),
                          Text("No threat data available.", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      )
                    ) : ListView.separated(
                    itemCount: threatTypes.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.borderPrimary),
                    itemBuilder: (context, index) {
                      final item = threatTypes[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['type'].toString(), style: const TextStyle(color: AppTheme.textPrimary)),
                        trailing: Text(item['count'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAttackers(List<dynamic> attackers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Attackers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          attackers.isEmpty ? const Center(child: Text("No Attackers Found", style: TextStyle(color: AppTheme.textSecondary))) :
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('IP Address', style: TextStyle(color: AppTheme.textSecondary))),
                DataColumn(label: Text('Country', style: TextStyle(color: AppTheme.textSecondary))),
                DataColumn(label: Text('Count', style: TextStyle(color: AppTheme.textSecondary))),
                DataColumn(label: Text('Severity', style: TextStyle(color: AppTheme.textSecondary))),
              ],
              rows: attackers.map((e) {
                final severity = (
                  e['highest_severity'] ??
                  e['severity'] ??
                  'UNKNOWN'
                ).toString().toUpperCase();

                Color sevColor = AppTheme.textSecondary;
                if (severity == 'CRITICAL') { sevColor = AppTheme.error; }
                else if (severity == 'HIGH') { sevColor = Colors.orange; }
                else if (severity == 'MEDIUM') { sevColor = AppTheme.warning; }
                else if (severity == 'LOW') { sevColor = AppTheme.success; }

                return DataRow(cells: [
                  DataCell(Text(e['source_ip']?.toString() ?? e['ip']?.toString() ?? 'N/A', style: const TextStyle(color: AppTheme.textPrimary))),
                  DataCell(Text(e['country']?.toString() ?? 'Unknown', style: const TextStyle(color: AppTheme.textPrimary))),
                  DataCell(Text(e['count']?.toString() ?? '0', style: const TextStyle(color: AppTheme.textPrimary))),
                  DataCell(Text(severity, style: TextStyle(fontWeight: FontWeight.w600, color: sevColor))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeline(Map<String, dynamic> responseAnalytics) {
    final events = [
      if ((responseAnalytics['blocks'] ?? 0) > 0)
        {'title': 'IPs Blocked', 'desc': 'System blocked ${responseAnalytics['blocks']} malicious IPs.', 'icon': LucideIcons.shieldX, 'color': AppTheme.error},
      if ((responseAnalytics['unblocks'] ?? 0) > 0)
        {'title': 'IPs Unblocked', 'desc': 'System unblocked ${responseAnalytics['unblocks']} IPs.', 'icon': LucideIcons.shieldCheck, 'color': AppTheme.success},
      if ((responseAnalytics['investigations'] ?? 0) > 0)
        {'title': 'Investigations Started', 'desc': '${responseAnalytics['investigations']} alerts are currently being investigated.', 'icon': LucideIcons.search, 'color': AppTheme.warning},
      if ((responseAnalytics['resolved'] ?? 0) > 0)
        {'title': 'Alerts Resolved', 'desc': '${responseAnalytics['resolved']} alerts have been successfully resolved.', 'icon': LucideIcons.shieldCheck, 'color': AppTheme.success},
      if ((responseAnalytics['ignored'] ?? 0) > 0)
        {'title': 'False Positives', 'desc': '${responseAnalytics['ignored']} alerts were flagged as false positives.', 'icon': LucideIcons.info, 'color': AppTheme.info},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Response Timeline Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          events.isEmpty ? const Text("No recent response activities.", style: TextStyle(color: AppTheme.textSecondary)) :
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final ev = events[index];
              return ListTile(
                leading: Icon(ev['icon'] as IconData, color: ev['color'] as Color),
                title: Text(ev['title'] as String, style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(ev['desc'] as String, style: const TextStyle(color: AppTheme.textSecondary)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExportPanel(ReportsProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export & Downloads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildExportBtn('Download PDF', 'pdf', provider.timeRange, LucideIcons.fileText),
              _buildExportBtn('Export JSON', 'json', provider.timeRange, LucideIcons.code),
              _buildExportBtn('CSV: Alerts', 'csv_alerts', provider.timeRange, LucideIcons.table),
              _buildExportBtn('CSV: Actions', 'csv_actions', provider.timeRange, LucideIcons.table),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportBtn(String label, String type, String timeRange, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => _downloadFile(type, timeRange),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.borderPrimary,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
