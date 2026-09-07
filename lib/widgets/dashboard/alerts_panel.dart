import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../widgets/common/common.dart';

/// Most recent alerts for the session on screen.
///
/// Severity is resolved through [CsSemantics] so an alert carries the same
/// colour, icon and label here as it does in every other list in the product.
class AlertsPanel extends StatelessWidget {
  const AlertsPanel({super.key});

  static const int _maxVisible = 10;

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final colors = CsColors.of(context);
        final alerts = provider.alerts;

        return AppCard(
          icon: LucideIcons.triangleAlert,
          iconColor: colors.primary,
          title: 'Recent Alerts',
          child: SizedBox(
            height: 450,
            child: alerts.isEmpty
                ? const EmptyState(
                    icon: LucideIcons.shieldOff,
                    title: 'No alert data available',
                    description: 'Waiting for live packet capture',
                    compact: true,
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount:
                        alerts.length > _maxVisible ? _maxVisible : alerts.length,
                    itemBuilder: (context, index) => _AlertCard(alert: alerts[index]),
                  ),
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final state = CsSemantics.severity(_severityOf(alert.severity), colors);

    return Container(
      margin: const EdgeInsets.only(bottom: CsSpacing.md),
      padding: const EdgeInsets.all(CsSpacing.lg),
      decoration: BoxDecoration(
        color: state.background,
        border: Border.all(color: state.border),
        borderRadius: CsRadius.mediumBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(state.icon, size: 15, color: state.foreground),
              ),
              const SizedBox(width: CsSpacing.sm),
              Expanded(
                child: Text(
                  alert.title,
                  style: text.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: CsSpacing.sm),
              _StatusChip(status: alert.status),
            ],
          ),
          const SizedBox(height: CsSpacing.sm),
          Text(
            alert.description,
            style: text.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: CsSpacing.sm),
          Text(
            alert.time,
            style: text.bodySmall.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  static Severity _severityOf(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Severity.low;
      case AlertSeverity.medium:
        return Severity.medium;
      case AlertSeverity.high:
        return Severity.high;
      case AlertSeverity.critical:
        return Severity.critical;
    }
  }
}

/// Lifecycle tag. Deliberately neutral: the card's colour belongs to severity,
/// so a second colour signal here would compete with it.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final label = status == 'FALSE_POSITIVE' ? 'IGNORED' : status;

    return Semantics(
      container: true,
      label: 'Alert status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          borderRadius: CsRadius.smallBorder,
        ),
        child: Text(
          label,
          style: text.caption.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
