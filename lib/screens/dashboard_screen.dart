import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// Only for `isMobile`. Its 1024px threshold is the one the dashboard has always
// used and is deliberately not the same as `CsBreakpoints.compact` (768px);
// switching it here would silently reflow every row on this screen.
import '../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/common/common.dart';
import '../widgets/dashboard/alerts_panel.dart';
import '../widgets/dashboard/malicious_ips_table.dart';
import '../widgets/dashboard/packet_classification.dart';
import '../widgets/dashboard/threat_score_card.dart';
import '../widgets/dashboard/traffic_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildKPIRow(context),
          const SizedBox(height: CsSpacing.xl),
          _buildTrafficAlertsRow(context),
          const SizedBox(height: CsSpacing.xl),
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
    final colors = CsColors.of(context);

    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final captured = _formatCount(dashboard.capturedPacketsCount);
        final analyzed = _formatCount(dashboard.analyzedPacketsCount);
        final pending = _formatCount(dashboard.pendingPacketsCount);
        final active = dashboard.isCurrentSessionVisible;
        final capturedLabel =
            active ? 'Current Session Captured' : 'Last Session Captured';
        final analyzedLabel =
            active ? 'Current Session Analyzed' : 'Last Session Analyzed';
        final fourthLabel =
            active ? 'Pending Analysis' : 'Last Session Analysis Completion';

        // Null, not the string 'N/A': a session that captured nothing has no
        // completion rate, and MetricCard renders that muted rather than in the
        // same weight as a real number.
        final fourthValue = active
            ? pending
            : dashboard.capturedPacketsCount == 0
                ? null
                : '${(dashboard.analysisCompletion * 100).toStringAsFixed(1)}%';

        final cards = <Widget>[
          MetricCard(
            icon: LucideIcons.network,
            label: capturedLabel,
            value: captured,
            iconColor: colors.info,
          ),
          MetricCard(
            icon: LucideIcons.activity,
            label: analyzedLabel,
            value: analyzed,
            iconColor: colors.info,
          ),
          MetricCard(
            icon: LucideIcons.clock,
            label: fourthLabel,
            value: fourthValue,
            iconColor: colors.warning,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              const ThreatScoreCard(),
              for (final card in cards) ...[
                const SizedBox(height: CsSpacing.xl),
                card,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: ThreatScoreCard()),
            for (final card in cards) ...[
              const SizedBox(width: CsSpacing.xl),
              Expanded(child: card),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTrafficAlertsRow(BuildContext context) {
    if (AppTheme.isMobile(context)) {
      return const Column(
        children: [
          TrafficChart(),
          SizedBox(height: CsSpacing.xl),
          AlertsPanel(),
        ],
      );
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: TrafficChart()),
        SizedBox(width: CsSpacing.xl),
        Expanded(flex: 1, child: AlertsPanel()),
      ],
    );
  }

  Widget _buildPacketIPsRow(BuildContext context) {
    if (AppTheme.isMobile(context)) {
      return const Column(
        children: [
          PacketClassification(),
          SizedBox(height: CsSpacing.xl),
          MaliciousIPsTable(),
        ],
      );
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: PacketClassification()),
        SizedBox(width: CsSpacing.xl),
        Expanded(flex: 2, child: MaliciousIPsTable()),
      ],
    );
  }
}
