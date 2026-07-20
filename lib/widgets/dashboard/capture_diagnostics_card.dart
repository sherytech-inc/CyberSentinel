import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class CaptureDiagnosticsCard extends StatelessWidget {
  const CaptureDiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final diag = provider.captureDiagnostics;
        final state = diag['state'] as String? ?? 'unknown';
        final interface = diag['config']?['interface'] as String? ?? 'unknown';
        final packetsCaptured = diag['packets_captured'] as int? ?? 0;
        
        final flowsStats = diag['flows'] as Map<String, dynamic>? ?? {};
        final activeFlows = flowsStats['active_flows'] as int? ?? 0;
        final finalizedTotal = flowsStats['finalized_total'] as int? ?? 0;

        final featureStats = diag['features'] as Map<String, dynamic>? ?? {};
        final extracted = featureStats['extracted'] as int? ?? 0;
        final failed = featureStats['failed'] as int? ?? 0;

        final errorMsg = diag['error'] as String?;

        final isActive = state == 'capturing';
        final isError = state == 'error' || errorMsg != null;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.borderPrimary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isError 
                          ? AppTheme.error.withOpacity(0.1)
                          : (isActive ? AppTheme.success.withOpacity(0.1) : AppTheme.info.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      LucideIcons.activity,
                      color: isError ? AppTheme.error : (isActive ? AppTheme.success : AppTheme.textSecondary),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  const Text(
                    'Capture Diagnostics',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isError ? AppTheme.error.withOpacity(0.1) : (isActive ? AppTheme.success.withOpacity(0.1) : AppTheme.bgSecondary),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: isError ? AppTheme.error : (isActive ? AppTheme.success : AppTheme.borderPrimary)),
                    ),
                    child: Text(
                      state.toUpperCase(),
                      style: TextStyle(
                        color: isError ? AppTheme.error : (isActive ? AppTheme.success : AppTheme.textSecondary),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (isError && errorMsg != null) ...[
                const SizedBox(height: AppTheme.spacing16),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.triangleAlert, color: AppTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMsg,
                          style: const TextStyle(color: AppTheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing24),
              _buildStatRow('Interface', interface),
              const SizedBox(height: AppTheme.spacing12),
              _buildStatRow('Packets Captured', packetsCaptured.toString()),
              const SizedBox(height: AppTheme.spacing12),
              _buildStatRow('Active Flows', activeFlows.toString()),
              const SizedBox(height: AppTheme.spacing12),
              _buildStatRow('Finalized Flows', finalizedTotal.toString()),
              const SizedBox(height: AppTheme.spacing12),
              _buildStatRow('Features Extracted', extracted.toString()),
              if (failed > 0) ...[
                const SizedBox(height: AppTheme.spacing12),
                _buildStatRow('Extraction Failed', failed.toString(), isError: true),
              ],
              const SizedBox(height: AppTheme.spacing12),
              _buildStatRow('WebSocket Status', provider.isWsConnected ? 'Connected' : 'Disconnected', isError: !provider.isWsConnected),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isError ? AppTheme.error : AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Mono',
          ),
        ),
      ],
    );
  }
}
