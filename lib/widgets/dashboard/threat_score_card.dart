import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/metrics_provider.dart';

class ThreatScoreCard extends StatelessWidget {
  const ThreatScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<MetricsProvider, int>(
      selector: (context, provider) => provider.metrics.threatScore,
      builder: (context, score, _) {
        final color = _getColor(score);

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
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      LucideIcons.shield,
                      color: color,
                      size: 24,
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
                    '${score.toStringAsFixed(0)} / 100',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              const Text(
                'Threat Score',
                style: TextStyle(
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
                  widthFactor: score / 100,
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
                    _getSeverityLabel(score),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      _getRiskDescription(score),
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
    return 'Safe';
  }

  String _getRiskDescription(int score) {
    if (score >= 70) return 'High Risk Detected';
    if (score >= 40) return 'Warning Risk Detected';
    return 'No Threats Detected';
  }


  Color _getColor(int score) {
    if (score >= 70) return AppTheme.error;
    if (score >= 40) return AppTheme.warning;
    return AppTheme.success;
  }
}
