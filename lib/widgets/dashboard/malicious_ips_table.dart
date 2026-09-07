import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../widgets/common/common.dart';

/// Highest-volume sources flagged by the classifier.
///
/// Threat level is resolved through [CsSemantics] so the same word carries the
/// same colour here as it does in the alerts panel and the threat response
/// screen. The badge text is the meaning carrier, so the icon is dropped to
/// keep the dense columns readable.
class MaliciousIPsTable extends StatelessWidget {
  const MaliciousIPsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final colors = CsColors.of(context);
        final text = CsTypography.of(context);
        final ips = provider.maliciousIPs;

        return AppCard(
          title: 'Top Malicious IPs',
          trailing: Text(
            'Last 24 hours',
            style: text.bodySmall.copyWith(color: colors.textTertiary),
          ),
          child: ips.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.globe,
                  title: 'No malicious sources recorded',
                  description:
                      'Flagged sources appear here once traffic has been analyzed.',
                  compact: true,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _TableHeader(),
                    for (final ip in ips) _TableRow(ip: ip),
                  ],
                ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final style = text.labelMedium.copyWith(
      color: colors.textTertiary,
      letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CsSpacing.lg,
        vertical: CsSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(CsRadius.medium),
          topRight: Radius.circular(CsRadius.medium),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('IP ADDRESS', style: style)),
          Expanded(flex: 2, child: Text('COUNTRY', style: style)),
          Expanded(
            flex: 2,
            child: Text('REQUESTS', textAlign: TextAlign.right, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text('THREAT', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.ip});

  final MaliciousIP ip;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CsSpacing.lg,
        vertical: CsSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              ip.ip,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.body.copyWith(
                color: colors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ip.country,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.body.copyWith(color: colors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ip.requests.toString(),
              textAlign: TextAlign.right,
              style: text.body.copyWith(color: colors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: SeverityBadge.fromString(
                ip.threatLevel,
                size: CsBadgeSize.sm,
                showIcon: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
