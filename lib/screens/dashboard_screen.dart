import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../models/global_metrics.dart';
import '../providers/dashboard_provider.dart';
import '../providers/metrics_provider.dart';
import '../widgets/dashboard/threat_score_card.dart';
import '../widgets/dashboard/kpi_card.dart';
import '../widgets/dashboard/traffic_chart.dart';
import '../widgets/dashboard/alerts_panel.dart';
import '../widgets/dashboard/packet_classification.dart';
import '../widgets/dashboard/malicious_ips_table.dart';
import '../widgets/dashboard/capture_diagnostics_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Row 1: KPI Cards
          _buildKPIRow(context),
          const SizedBox(height: AppTheme.spacing16),

          // Row 2: Traffic Chart + Alerts
          _buildTrafficAlertsRow(context),
          const SizedBox(height: AppTheme.spacing16),

          // Row 3: Packet Classification + Malicious IPs
          _buildPacketIPsRow(context),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildKPIRow(BuildContext context) {
    final isMobile = AppTheme.isMobile(context);

    return Selector<MetricsProvider, GlobalSecurityMetrics>(
      selector: (context, provider) => provider.metrics,
      builder: (context, metrics, _) {
        final activeThreats = metrics.activeThreats.toString();
        final packetsCount = _formatCount(metrics.totalPackets);
        final suspiciousIPs = metrics.suspiciousIps.toString();

        if (isMobile) {
          return Column(
            children: [
              const ThreatScoreCard(),
              const SizedBox(height: AppTheme.spacing16),
              KPICard(
                icon: LucideIcons.triangleAlert,
                label: 'Active Threats',
                value: activeThreats,
                iconColor: AppTheme.error,
                iconBg: AppTheme.error.withOpacity(0.1),
              ),
              const SizedBox(height: AppTheme.spacing16),
              KPICard(
                icon: LucideIcons.activity,
                label: 'Packets Analyzed',
                value: packetsCount,
                iconColor: AppTheme.info,
                iconBg: AppTheme.info.withOpacity(0.1),
              ),
              const SizedBox(height: AppTheme.spacing16),
              KPICard(
                icon: LucideIcons.globe,
                label: 'Suspicious IPs',
                value: suspiciousIPs,
                iconColor: AppTheme.warning,
                iconBg: AppTheme.warning.withOpacity(0.1),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Expanded(child: ThreatScoreCard()),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: KPICard(
                icon: LucideIcons.triangleAlert,
                label: 'Active Threats',
                value: activeThreats,
                iconColor: AppTheme.error,
                iconBg: AppTheme.error.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: KPICard(
                icon: LucideIcons.activity,
                label: 'Packets Analyzed',
                value: packetsCount,
                iconColor: AppTheme.info,
                iconBg: AppTheme.info.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: KPICard(
                icon: LucideIcons.globe,
                label: 'Suspicious IPs',
                value: suspiciousIPs,
                iconColor: AppTheme.warning,
                iconBg: AppTheme.warning.withOpacity(0.1),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildTrafficAlertsRow(BuildContext context) {
    final isMobile = AppTheme.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          const TrafficChart(),
          const SizedBox(height: AppTheme.spacing16),
          const AlertsPanel(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 2,
          child: TrafficChart(),
        ),
        const SizedBox(width: AppTheme.spacing16),
        const Expanded(
          flex: 1,
          child: Column(
            children: [
              AlertsPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPacketIPsRow(BuildContext context) {
    final isMobile = AppTheme.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          const PacketClassification(),
          const SizedBox(height: AppTheme.spacing16),
          const MaliciousIPsTable(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 1,
          child: PacketClassification(),
        ),
        const SizedBox(width: AppTheme.spacing16),
        const Expanded(
          flex: 2,
          child: MaliciousIPsTable(),
        ),
      ],
    );
  }
}
