import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class AlertsPanel extends StatelessWidget {
  const AlertsPanel({super.key});

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
                children: const [
                  Icon(
                    LucideIcons.triangleAlert,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Recent Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing24),
              ...provider.alerts.map((alert) => _buildAlert(alert)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlert(Alert alert) {
    Color getSeverityColor(AlertSeverity severity) {
      switch (severity) {
        case AlertSeverity.critical:
          return AppTheme.error;
        case AlertSeverity.high:
          return AppTheme.warning;
        case AlertSeverity.medium:
          return Colors.orange.shade400;
        case AlertSeverity.low:
          return AppTheme.info;
      }
    }

    final color = getSeverityColor(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            alert.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            alert.time,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
