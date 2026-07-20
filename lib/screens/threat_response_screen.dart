import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/threat_response_provider.dart';
import '../models/response_action.dart';
import '../core/state/state_coordinator.dart';

class ThreatResponseScreen extends StatefulWidget {
  const ThreatResponseScreen({super.key});

  @override
  State<ThreatResponseScreen> createState() => _ThreatResponseScreenState();
}

class _ThreatResponseScreenState extends State<ThreatResponseScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshThreatResponse(ThreatResponseProvider provider) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        provider.fetchThreatQueue(),
        provider.fetchActionHistory(),
        // TODO: call MetricsProvider and other providers refresh once Coordinator is built
      ]);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatResponseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.threatQueue.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKPISection(context, provider),
              const SizedBox(height: AppTheme.spacing24),
              _buildThreatQueueSection(context, provider),
              const SizedBox(height: AppTheme.spacing24),
              AppTheme.isMobile(context)
                  ? Column(
                      children: [
                        _buildActionHistorySection(context, provider),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildActionHistorySection(context, provider)),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPISection(BuildContext context, ThreatResponseProvider provider) {
    final kpis = [
      _buildKPICard(LucideIcons.shieldAlert, 'Active Threats', provider.activeThreats.toString(), AppTheme.error),
      _buildKPICard(LucideIcons.ban, 'Blocked IPs', provider.blockedIPsCount.toString(), AppTheme.warning),
      _buildKPICard(LucideIcons.activity, 'Total Actions', provider.totalActions.toString(), AppTheme.info),
    ];

    if (AppTheme.isMobile(context)) {
      return Column(children: kpis.map((w) => Padding(padding: const EdgeInsets.only(bottom: AppTheme.spacing16), child: w)).toList());
    }

    return Row(
      children: kpis.map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: AppTheme.spacing16), child: w))).toList(),
    );
  }

  Widget _buildKPICard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreatQueueSection(BuildContext context, ThreatResponseProvider provider) {
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
            children: [
              const Icon(LucideIcons.list, color: AppTheme.primary, size: 20),
              const SizedBox(width: AppTheme.spacing12),
              const Text('Active Threat Queue', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: _isRefreshing 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary))
                    : const Icon(LucideIcons.refreshCw, color: AppTheme.textSecondary, size: 18),
                onPressed: () => _refreshThreatResponse(provider),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (provider.threatQueue.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.shieldCheck, color: AppTheme.success, size: 32),
                    SizedBox(height: 12),
                    Text('No active threats detected', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: provider.threatQueue.map((threat) => _buildThreatRow(context, provider, threat)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildThreatRow(BuildContext context, ThreatResponseProvider provider, Map<String, dynamic> threat) {
    final alertId = threat['alert_id'] ?? '';
    final ip = threat['source_ip'] ?? 'Unknown';
    final severity = threat['severity'] ?? 'LOW';
    final score = threat['threat_score'] ?? 0.0;
    final isExpanded = provider.expandedThreatId == alertId;
    final createdAt = DateTime.tryParse(threat['created_at'] ?? '') ?? DateTime.now();

    return Card(
      color: AppTheme.bgPrimary,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderPrimary),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(ip, style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                const SizedBox(width: AppTheme.spacing12),
                _buildSeverityBadge(severity),
                const SizedBox(width: AppTheme.spacing12),
                Text('Score: ${score.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt.toLocal()), style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    provider.investigateThreat(alertId);
                    context.push('/investigation/$alertId');
                  },
                  icon: const Icon(LucideIcons.microscope, size: 16),
                  label: const Text('Open Investigation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                TextButton(
                  onPressed: provider.isActionPending(alertId) ? null : () => _showBlockDialog(context, provider, ip, alertId),
                  child: provider.isActionPending(alertId) 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Block', style: TextStyle(color: AppTheme.error)),
                ),
                TextButton(
                  onPressed: provider.isActionPending(alertId) ? null : () async {
                    final res = await provider.ignoreThreat(alertId);
                    if (context.mounted) {
                      if (res['success'] == true) {
                        await StateCoordinator(context).afterThreatAction(ThreatActionType.ignore);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res['message'] ?? 'Threat ignored'),
                        backgroundColor: res['success'] == true ? AppTheme.success : AppTheme.error,
                      ));
                    }
                  },
                  child: const Text('Ignore', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                IconButton(
                  icon: Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: AppTheme.textSecondary),
                  onPressed: () => provider.toggleExpanded(alertId),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderPrimary)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(threat['summary'] ?? '', style: const TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(height: AppTheme.spacing12),
                  if (threat['explanation'] != null)
                    ...((threat['explanation'] as List<dynamic>).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppTheme.textSecondary)),
                              Expanded(child: Text(e.toString(), style: const TextStyle(color: AppTheme.textSecondary))),
                            ],
                          ),
                        ))),
                  const SizedBox(height: AppTheme.spacing16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: provider.isActionPending(alertId) ? null : () async {
                          final res = await provider.resolveThreat(alertId);
                          if (context.mounted) {
                            if (res['success'] == true) {
                              await StateCoordinator(context).afterThreatAction(ThreatActionType.resolve);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(res['message'] ?? 'Threat resolved'),
                              backgroundColor: res['success'] == true ? AppTheme.success : AppTheme.error,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                        child: provider.isActionPending(alertId)
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Mark Resolved', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    final color = severity == 'CRITICAL'
        ? AppTheme.error
        : severity == 'HIGH'
            ? AppTheme.warning
            : severity == 'MEDIUM'
                ? const Color(0xFFF59E0B)
                : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(severity, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionHistorySection(BuildContext context, ThreatResponseProvider provider) {
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
            children: [
              const Icon(LucideIcons.history, color: AppTheme.primary, size: 20),
              const SizedBox(width: AppTheme.spacing12),
              const Text('Action History', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: AppTheme.textSecondary, size: 18),
                onPressed: () => provider.fetchActionHistory(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (provider.actionHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.shieldCheck, color: AppTheme.success, size: 32),
                    SizedBox(height: 12),
                    Text('No action history', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.actionHistory.length,
              itemBuilder: (context, index) {
                final action = provider.actionHistory[index];
                final isBlock = action.action == 'BLOCK';
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBlock ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: isBlock ? AppTheme.error.withOpacity(0.3) : AppTheme.success.withOpacity(0.3)),
                    ),
                    child: Text(action.action, style: TextStyle(color: isBlock ? AppTheme.error : AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Text(action.ip, style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'monospace')),
                      const SizedBox(width: 8),
                      if (action.enforced == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text('OS ENFORCED', style: TextStyle(color: AppTheme.success, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.reason ?? 'No reason provided', style: const TextStyle(color: AppTheme.textSecondary)),
                      if (action.note != null) ...[
                        const SizedBox(height: 4),
                        Text('Note: ${action.note}', style: const TextStyle(color: AppTheme.textTertiary, fontStyle: FontStyle.italic)),
                      ],
                      if (action.analystName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.user, size: 12, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(action.analystName!, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(DateFormat('yyyy-MM-dd HH:mm').format(action.createdAt.toLocal()), style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, ThreatResponseProvider provider, String ip, String alertId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Block IP', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Block $ip from all network access?', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recorded only - Not enforced at OS level',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Reason',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.borderPrimary)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.isEmpty ? 'Blocked manually' : reasonController.text;
              Navigator.pop(ctx);
              final res = await provider.blockIP(ip, reason, alertId);
              if (context.mounted) {
                if (res['success'] == true) {
                  await StateCoordinator(context).afterThreatAction(ThreatActionType.block);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['message'] ?? 'Action completed'),
                  backgroundColor: res['success'] == true ? AppTheme.success : AppTheme.error,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Confirm Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
