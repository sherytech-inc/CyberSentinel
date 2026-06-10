import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

enum ChangeType {
  positive,
  negative,
  neutral,
}

class KPICard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final ChangeType changeType;
  final Color iconColor;
  final Color iconBg;

  const KPICard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.changeType,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    Color changeColor;
    switch (changeType) {
      case ChangeType.positive:
        changeColor = AppTheme.success;
        break;
      case ChangeType.negative:
        changeColor = AppTheme.error;
        break;
      case ChangeType.neutral:
        changeColor = AppTheme.textSecondary;
        break;
    }

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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                change,
                style: TextStyle(
                  fontSize: 14,
                  color: changeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
