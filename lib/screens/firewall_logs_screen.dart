import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/firewall_logs_provider.dart';
import '../providers/firewall_actions_provider.dart';
import '../models/firewall_log.dart';
import '../models/firewall_action_model.dart';
import '../services/api_service.dart';

class FirewallLogsScreen extends StatefulWidget {
  const FirewallLogsScreen({super.key});

  @override
  State<FirewallLogsScreen> createState() => _FirewallLogsScreenState();
}

class _FirewallLogsScreenState extends State<FirewallLogsScreen> {
  int _selectedTab = 0; // 0: OS Logs, 1: SOC Actions

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirewallLogsProvider, FirewallActionsProvider>(
      builder: (context, logsProvider, actionsProvider, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50) {
              if (_selectedTab == 0 && logsProvider.hasMore && !logsProvider.isLoading) {
                logsProvider.fetchLogs();
              } else if (_selectedTab == 1 && actionsProvider.hasMore && !actionsProvider.isLoading) {
                actionsProvider.fetchActions();
              }
            }
            return false;
          },
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopBar(context, logsProvider, actionsProvider),
                const SizedBox(height: AppTheme.spacing16),
                _buildMainContent(context, logsProvider, actionsProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, FirewallLogsProvider logsProvider, FirewallActionsProvider actionsProvider) {
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
              Tooltip(
                message: 'Upload UFW or Windows Firewall logs',
                child: ElevatedButton.icon(
                  onPressed: () => _handleUploadLogs(context, logsProvider),
                  icon: const Icon(LucideIcons.cloudUpload, size: 16),
                  label: const Text('Import Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _handleExport(context, logsProvider),
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
              if (logsProvider.isLoading || actionsProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 20),
                  onPressed: () {
                    logsProvider.fetchLogs();
                    actionsProvider.fetchActions();
                  },
                  tooltip: 'Manual Refresh',
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _handleUploadLogs(BuildContext context, FirewallLogsProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['log', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final name = file.name;

        if (bytes == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to read file data.'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          return;
        }

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }

        final uploadResult = await LocalAgentClient.uploadFirewallLogs(name, bytes);

        if (context.mounted) {
          Navigator.pop(context); // close dialog
          if (uploadResult.containsKey('error') && uploadResult['error'] == true) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Upload failed: ${uploadResult['message']}'),
                 backgroundColor: AppTheme.error,
               ),
             );
          } else {
             // Authoritative refresh
             provider.fetchLogs();
             
             final imported = uploadResult['imported'] ?? 0;
             final rejected = uploadResult['rejected'] ?? 0;
             final format = uploadResult['format'] ?? 'unknown';
             
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Success: Imported $imported entries ($format). Rejected: $rejected.'),
                 backgroundColor: AppTheme.success,
               ),
             );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

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
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────────

  Widget _buildMainContent(
      BuildContext context, FirewallLogsProvider logsProvider, FirewallActionsProvider actionsProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              border: Border.all(color: AppTheme.borderPrimary),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSegmentedControl(),
                if (_selectedTab == 0) _buildLogsTable(logsProvider),
                if (_selectedTab == 1) _buildActionsTable(actionsProvider),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildInsightsPanel(logsProvider, actionsProvider)),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Firewall Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTabButton(0, 'OS Firewall Logs'),
              const SizedBox(width: 8),
              _buildTabButton(1, 'SOC Actions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderPrimary,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLogsTable(FirewallLogsProvider provider) {
    if (provider.logs.isEmpty) {
      return _buildEmptyState(
        'No OS firewall events recorded',
        'Log import is not available in this build while RB-021 remains open.',
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AppTheme.borderPrimary),
        columns: const [
          DataColumn(label: Text('SOURCE IP')),
          DataColumn(label: Text('DEST PORT')),
          DataColumn(label: Text('ACTION')),
          DataColumn(label: Text('RULE')),
          DataColumn(label: Text('LOGGED AT')),
        ],
        rows: provider.logs.map((log) {
          return DataRow(cells: [
            DataCell(Text(log.sourceIp, style: const TextStyle(fontFamily: 'monospace'))),
            DataCell(Text(log.destinationPort?.toString() ?? 'Unavailable')),
            DataCell(_buildActionBadge(log.action.name, log.action == FirewallAction.blocked)),
            DataCell(Text(log.ruleName ?? 'Unavailable', style: const TextStyle(fontFamily: 'monospace'))),
            DataCell(Text(log.loggedAt.toString(), style: const TextStyle(fontFamily: 'monospace'))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildActionsTable(FirewallActionsProvider provider) {
    if (provider.actions.isEmpty) {
      return _buildEmptyState(
        'No SOC actions recorded',
        'Create an analyst block or unblock action from the Threat Response screen.',
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AppTheme.borderPrimary),
        columns: const [
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('ACTION')),
          DataColumn(label: Text('REASON')),
          DataColumn(label: Text('SOURCE')),
          DataColumn(label: Text('ENFORCEMENT')),
          DataColumn(label: Text('CREATED AT')),
        ],
        rows: provider.actions.map((action) {
          return DataRow(cells: [
            DataCell(Text(action.ip, style: const TextStyle(fontFamily: 'monospace'))),
            DataCell(_buildActionBadge(action.action, action.action.toUpperCase() == 'BLOCK')),
            DataCell(Text(action.reason ?? 'N/A')),
            DataCell(Text(action.source)),
            DataCell(_buildEnforcementBadge(action.recorded, action.enforced)),
            DataCell(Text(action.createdAt.toString(), style: const TextStyle(fontFamily: 'monospace'))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildEnforcementBadge(bool recorded, bool enforced) {
    Color color;
    String label;
    if (enforced) {
      color = AppTheme.success;
      label = 'Enforced';
    } else if (recorded) {
      color = AppTheme.warning;
      label = 'Recorded Only';
    } else {
      color = AppTheme.error;
      label = 'Failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionBadge(String label, bool isBlock) {
    final color = isBlock ? AppTheme.error : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Widget _buildEmptyState(String message, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.shieldCheck, size: 48, color: AppTheme.success),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsPanel(FirewallLogsProvider logsProvider, FirewallActionsProvider actionsProvider) {
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
            children: [
              const Icon(LucideIcons.chartBar, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedTab == 0 ? 'OS Firewall Insights' : 'SOC Actions Insights',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_selectedTab == 0) ...[
            _buildStatBar(
              'Blocked (OS)',
              logsProvider.blockedCount,
              logsProvider.logs.length,
              AppTheme.error,
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'Allowed (OS)',
              logsProvider.allowedCount,
              logsProvider.logs.length,
              AppTheme.success,
            ),
          ] else ...[
            _buildStatBar(
              'Block Actions',
              actionsProvider.blockCount,
              actionsProvider.actions.length,
              AppTheme.error,
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'Unblock Actions',
              actionsProvider.unblockCount,
              actionsProvider.actions.length,
              AppTheme.success,
            ),
            const SizedBox(height: 24),
            const Text(
              'Enforcement Status',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'Enforced',
              actionsProvider.enforcedCount,
              actionsProvider.actions.length,
              AppTheme.success,
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'Recorded Only',
              actionsProvider.recordedCount,
              actionsProvider.actions.length,
              AppTheme.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, int total, Color color) {
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
