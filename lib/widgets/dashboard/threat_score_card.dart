import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class ThreatScoreCard extends StatelessWidget {
  const ThreatScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final showCurrentSession = dashboardProvider.isCurrentSessionVisible;
        final score = showCurrentSession
            ? dashboardProvider.currentSessionThreatScore
            : dashboardProvider.lastSessionThreatScore;
        final hasScore = score != null;
        final displayScore = score ?? 0;
        final color =
            hasScore ? _getColor(displayScore) : AppTheme.textTertiary;

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
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      LucideIcons.shield,
                      color: color,
                      size: 22,
                    ),
                  ),
                  Text(
                    'RISK LEVEL',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasScore
                        ? '${displayScore.toStringAsFixed(0)} / 100'
                        : 'N/A',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                showCurrentSession
                    ? 'Threat Score'
                    : 'Last Session Threat Score',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.borderPrimary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: hasScore ? displayScore / 100 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showCurrentSession
                        ? (hasScore
                            ? dashboardProvider.isStopping
                                ? 'Finalizing session'
                                : _getSeverityLabel(displayScore)
                            : dashboardProvider.isStopping
                                ? 'Finalizing session'
                                : 'Monitoring active — analysis pending')
                        : 'Monitoring inactive',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      hasScore
                          ? showCurrentSession
                              ? _getRiskDescription(displayScore)
                              : '${_getRiskDescription(displayScore)} — Last completed session'
                          : '',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSeverityLabel(int score) {
    if (score >= 70) return 'Critical';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  String _getRiskDescription(int score) {
    if (score >= 70) return 'High Risk Detected';
    if (score >= 40) return 'Warning Risk Detected';
    return 'Low Risk';
  }

  Color _getColor(int score) {
    if (score >= 70) return AppTheme.error;
    if (score >= 40) return AppTheme.warning;
    return AppTheme.success;
  }
}
