import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class MaliciousIPsTable extends StatelessWidget {
  const MaliciousIPsTable({super.key});

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Top Malicious IPs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Last 24 hours',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing24),
              _buildTableHeader(),
              ...provider.maliciousIPs
                  .map((ip) => _buildTableRow(ip))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.borderPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusMd),
          topRight: Radius.circular(AppTheme.radiusMd),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 3,
            child: Text(
              'IP ADDRESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'COUNTRY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'REQUESTS',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'THREAT',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(MaliciousIP ip) {
    Color getThreatColor(String level) {
      switch (level) {
        case 'Critical':
          return AppTheme.error;
        case 'High':
          return AppTheme.warning;
        case 'Medium':
          return Colors.orange.shade400;
        default:
          return AppTheme.info;
      }
    }

    final threatColor = getThreatColor(ip.threatLevel);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              ip.ip,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ip.country,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ip.requests.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: threatColor.withOpacity(0.1),
                  border: Border.all(color: threatColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  ip.threatLevel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: threatColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
