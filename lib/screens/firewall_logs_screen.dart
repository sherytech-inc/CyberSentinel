import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/firewall_logs_provider.dart';
import '../models/firewall_log.dart';

class FirewallLogsScreen extends StatelessWidget {
  const FirewallLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FirewallLogsProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(context, provider),
              const SizedBox(height: AppTheme.spacing16),
              _buildMainContent(context, provider),
            ],
          ),
        );
      },
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, FirewallLogsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleUploadLogs(context),
                icon: const Icon(LucideIcons.upload, size: 16),
                label: const Text('Upload Logs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _handleExport(context, provider),
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: provider.autoFetch,
                onChanged: (_) => provider.toggleAutoFetch(),
              ),
              const Text('Auto-fetch logs'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  /// Shows a snackbar indicating upload is not yet connected to a backend.
  /// When the backend is ready, replace this with a file picker + API call.
  void _handleUploadLogs(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.info, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
                'File upload will be available once the backend is connected.'),
          ],
        ),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  /// Shows a snackbar with export status.
  /// When the backend is ready, replace this with a real PDF/CSV export call.
  void _handleExport(BuildContext context, FirewallLogsProvider provider) {
    if (provider.logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.triangleAlert, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('No logs available to export.'),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.download, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Exporting ${provider.logs.length} log entries...'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────────

  Widget _buildMainContent(
      BuildContext context, FirewallLogsProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildLogsTable(provider)),
        const SizedBox(width: 16),
        Expanded(child: _buildInsightsPanel(provider)),
      ],
    );
  }

  Widget _buildLogsTable(FirewallLogsProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firewall Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${provider.logs.length} events in the last hour',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  MaterialStateProperty.all(AppTheme.borderPrimary),
              columns: const [
                DataColumn(label: Text('IP ADDRESS')),
                DataColumn(label: Text('PORT')),
                DataColumn(label: Text('ACTION')),
                DataColumn(label: Text('RULE')),
                DataColumn(label: Text('TIMESTAMP')),
              ],
              rows: provider.logs.map((log) {
                return DataRow(cells: [
                  DataCell(Text(
                    log.ip,
                    style: const TextStyle(fontFamily: 'monospace'),
                  )),
                  DataCell(Text(log.port.toString())),
                  DataCell(Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.action == FirewallAction.blocked
                          ? AppTheme.error.withOpacity(0.1)
                          : AppTheme.success.withOpacity(0.1),
                      border: Border.all(
                        color: log.action == FirewallAction.blocked
                            ? AppTheme.error.withOpacity(0.2)
                            : AppTheme.success.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.action.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: log.action == FirewallAction.blocked
                            ? AppTheme.error
                            : AppTheme.success,
                      ),
                    ),
                  )),
                  DataCell(Text(
                    log.rule,
                    style: const TextStyle(fontFamily: 'monospace'),
                  )),
                  DataCell(Text(
                    log.timestamp,
                    style: const TextStyle(fontFamily: 'monospace'),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel(FirewallLogsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Icon(LucideIcons.chartBar, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatBar(
            'Blocked',
            provider.blockedCount,
            provider.logs.length,
            AppTheme.error,
          ),
          const SizedBox(height: 12),
          _buildStatBar(
            'Allowed',
            provider.allowedCount,
            provider.logs.length,
            AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, int total, Color color) {
    // Guard against division by zero if logs list is empty
    final double fraction = total > 0 ? value / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color)),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.borderPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
