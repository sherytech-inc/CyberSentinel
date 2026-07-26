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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ThreatResponseProvider>().ensureLoaded();
      }
    });
  }

  Future<void> _refreshThreatResponse(ThreatResponseProvider provider) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        provider.fetchOverview(),
        provider.fetchThreatQueue(),
        provider.fetchAlertHistory(),
        provider.fetchActionHistory(),
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
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.error != null) ...[
                _buildErrorBanner(provider.error!),
                const SizedBox(height: AppTheme.spacing16),
              ],
              _buildKPISection(context, provider),
              const SizedBox(height: AppTheme.spacing24),
              _buildThreatQueueSection(context, provider),
              const SizedBox(height: AppTheme.spacing24),
              _buildAlertHistorySection(context, provider),
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
                        Expanded(
                            child:
                                _buildActionHistorySection(context, provider)),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        border: Border.all(color: AppTheme.warning.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            color: AppTheme.warning,
            size: 18,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(
      BuildContext context, ThreatResponseProvider provider) {
    final kpis = [
      _buildKPICard(LucideIcons.shieldAlert, 'Active Threats',
          provider.activeThreats.toString(), AppTheme.error),
      _buildKPICard(LucideIcons.ban, 'OS-Enforced Blocks',
          provider.blockedIPsCount.toString(), AppTheme.warning),
      _buildKPICard(LucideIcons.activity, 'Total Actions',
          provider.totalActions.toString(), AppTheme.info),
    ];

    if (AppTheme.isMobile(context)) {
      return Column(
          children: kpis
              .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                  child: w))
              .toList());
    }

    return Row(
      children: kpis
          .map((w) => Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacing16),
                  child: w)))
          .toList(),
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
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreatQueueSection(
      BuildContext context, ThreatResponseProvider provider) {
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
              const Expanded(
                child: Text(
                  'Active Threat Queue',
                  softWrap: true,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.textSecondary))
                    : const Icon(LucideIcons.refreshCw,
                        color: AppTheme.textSecondary, size: 18),
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
                    Icon(LucideIcons.shield,
                        color: AppTheme.textTertiary, size: 32),
                    SizedBox(height: 12),
                    Text('No open alert records',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    SizedBox(height: 4),
                    Text(
                      'No alerts is not proof that the network is safe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: provider.threatQueue
                  .map((threat) => _buildThreatRow(context, provider, threat))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildThreatRow(BuildContext context, ThreatResponseProvider provider,
      Map<String, dynamic> threat) {
    final alertId = threat['alert_id'] ?? '';
    final ip = threat['source_ip'] ?? 'Unknown';
    final severity = threat['severity'] ?? 'LOW';
    final score = threat['threat_score'] ?? 0.0;
    final isExpanded = provider.expandedThreatId == alertId;
    final createdAt =
        DateTime.tryParse(threat['created_at'] ?? '') ?? DateTime.now();

    return Card(
      key: ValueKey('active-alert-$alertId'),
      color: AppTheme.bgPrimary,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderPrimary),
      ),
      child: Column(
        children: [
          ListTile(
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppTheme.spacing12,
              runSpacing: AppTheme.spacing8,
              children: [
                Text(ip,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold)),
                _buildSeverityBadge(severity),
                Text('Score: ${score.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            subtitle: Text(
                DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt.toLocal()),
                style: const TextStyle(
                    color: AppTheme.textTertiary, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Open investigation',
                  onPressed: provider.isActionPending(alertId)
                      ? null
                      : () => _openInvestigation(
                            context,
                            provider,
                            alertId,
                          ),
                  icon: const Icon(
                    LucideIcons.microscope,
                    color: AppTheme.primary,
                    size: 19,
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !provider.isActionPending(alertId),
                  tooltip: 'Alert actions',
                  color: AppTheme.bgSecondary,
                  onSelected: (action) => _handleAlertMenuAction(
                    context,
                    provider,
                    action,
                    ip,
                    alertId,
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'block', child: Text('Record block')),
                    PopupMenuItem(
                      value: 'whitelist',
                      child: Text('Record whitelist'),
                    ),
                    PopupMenuItem(value: 'ignore', child: Text('Ignore alert')),
                  ],
                  child: provider.isActionPending(alertId)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(
                          LucideIcons.ellipsisVertical,
                          color: AppTheme.textSecondary,
                          size: 19,
                        ),
                ),
                IconButton(
                  icon: Icon(
                      isExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      color: AppTheme.textSecondary),
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
                  Text(threat['summary'] ?? '',
                      style: const TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(height: AppTheme.spacing12),
                  if (threat['explanation'] != null)
                    ...((threat['explanation'] as List<dynamic>)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary)),
                                  Expanded(
                                      child: Text(e.toString(),
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary))),
                                ],
                              ),
                            ))),
                  const SizedBox(height: AppTheme.spacing16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: provider.isActionPending(alertId)
                            ? null
                            : () async {
                                final res =
                                    await provider.resolveThreat(alertId);
                                if (context.mounted) {
                                  if (res['success'] == true) {
                                    await StateCoordinator(context)
                                        .afterThreatAction(
                                            ThreatActionType.resolve);
                                  }
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        res['message'] ?? 'Threat resolved'),
                                    backgroundColor: res['success'] == true
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success),
                        child: provider.isActionPending(alertId)
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Mark Resolved',
                                style: TextStyle(color: Colors.white)),
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
      child: Text(severity,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAlertHistorySection(
    BuildContext context,
    ThreatResponseProvider provider,
  ) {
    final alerts = provider.filteredAlertHistory;
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
          const Row(
            children: [
              Icon(LucideIcons.archive, color: AppTheme.primary, size: 20),
              SizedBox(width: AppTheme.spacing12),
              Text(
                'Alert History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: ThreatAlertFilter.values
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filter.label),
                    selected: provider.alertFilter == filter,
                    onSelected: (_) => provider.setAlertFilter(filter),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing24),
              child: Center(
                child: Text(
                  'No alert records match this filter.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...alerts.take(50).map(_buildHistoryAlertRow),
        ],
      ),
    );
  }

  Widget _buildHistoryAlertRow(Map<String, dynamic> alert) {
    final alertId = alert['alert_id']?.toString() ?? '';
    final status = alert['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    final severity = alert['severity']?.toString().toUpperCase() ?? 'UNKNOWN';
    final source = alert['source_ip']?.toString() ?? 'Unknown IP';
    final timestamp = DateTime.tryParse(
      alert['updated_at']?.toString() ?? alert['created_at']?.toString() ?? '',
    );
    return ListTile(
      key: ValueKey('alert-history-$alertId'),
      contentPadding: EdgeInsets.zero,
      leading: _buildSeverityBadge(severity),
      title: Text(
        source,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontFamily: 'monospace',
        ),
      ),
      subtitle: Text(
        alert['summary']?.toString() ?? 'No summary available.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            status == 'FALSE_POSITIVE' ? 'IGNORED' : status,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (timestamp != null)
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toLocal()),
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionHistorySection(
      BuildContext context, ThreatResponseProvider provider) {
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
              const Icon(LucideIcons.history,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: AppTheme.spacing12),
              const Expanded(
                child: Text(
                  'Action History',
                  softWrap: true,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw,
                    color: AppTheme.textSecondary, size: 18),
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
                    Icon(LucideIcons.history,
                        color: AppTheme.textTertiary, size: 32),
                    SizedBox(height: 12),
                    Text('No action history',
                        style: TextStyle(color: AppTheme.textSecondary)),
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
                final isEnforced = action.enforced == true;
                return ListTile(
                  key: ValueKey('response-action-${action.id}'),
                  leading: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnforced && isBlock
                          ? AppTheme.error.withOpacity(0.1)
                          : AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                          color: isEnforced && isBlock
                              ? AppTheme.error.withOpacity(0.3)
                              : AppTheme.warning.withOpacity(0.3)),
                    ),
                    child: Text(action.action,
                        style: TextStyle(
                            color: isEnforced && isBlock
                                ? AppTheme.error
                                : AppTheme.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Text(action.ip,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontFamily: 'monospace')),
                      const SizedBox(width: 8),
                      if (action.enforced == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('OS ENFORCED',
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.reason ?? 'No reason provided',
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        action.message ??
                            (isEnforced
                                ? 'Operating-system enforcement confirmed.'
                                : 'Recorded only; not enforced by the operating system.'),
                        style: TextStyle(
                          color:
                              isEnforced ? AppTheme.success : AppTheme.warning,
                          fontSize: 11,
                        ),
                      ),
                      if (action.note != null) ...[
                        const SizedBox(height: 4),
                        Text('Note: ${action.note}',
                            style: const TextStyle(
                                color: AppTheme.textTertiary,
                                fontStyle: FontStyle.italic)),
                      ],
                      if (action.analystName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.user,
                                size: 12, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(action.analystName!,
                                style: const TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm')
                            .format(action.createdAt.toLocal()),
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      if (isBlock)
                        IconButton(
                          tooltip: 'Record unblock request',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _recordUnblock(
                            context,
                            provider,
                            action,
                          ),
                          icon: const Icon(
                            LucideIcons.undo2,
                            size: 16,
                            color: AppTheme.info,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openInvestigation(
    BuildContext context,
    ThreatResponseProvider provider,
    String alertId,
  ) async {
    final result = await provider.investigateThreat(alertId);
    if (!context.mounted) return;
    if (result['success'] == true) {
      context.push('/investigation/$alertId');
    } else {
      _showActionResult(context, result);
    }
  }

  Future<void> _handleAlertMenuAction(
    BuildContext context,
    ThreatResponseProvider provider,
    String action,
    String ip,
    String alertId,
  ) async {
    if (action == 'block') {
      _showBlockDialog(context, provider, ip, alertId);
      return;
    }

    Map<String, dynamic> result;
    if (action == 'whitelist') {
      result = await provider.whitelistIP(
        ip,
        'Whitelist requested by analyst',
        alertId,
      );
    } else {
      result = await provider.ignoreThreat(alertId);
      if (result['success'] == true && context.mounted) {
        await StateCoordinator(context)
            .afterThreatAction(ThreatActionType.ignore);
      }
    }
    if (context.mounted) {
      _showActionResult(context, result);
    }
  }

  Future<void> _recordUnblock(
    BuildContext context,
    ThreatResponseProvider provider,
    ResponseAction action,
  ) async {
    final result = await provider.unblockIP(
      action.ip,
      'Unblock requested by analyst',
      action.relatedAlert ?? action.id,
    );
    if (context.mounted) {
      _showActionResult(context, result);
    }
  }

  void _showActionResult(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    final success = result['success'] == true;
    final enforced = result['enforced'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (success
                  ? 'Action completed.'
                  : 'The action could not be completed.'),
        ),
        backgroundColor: !success
            ? AppTheme.error
            : enforced
                ? AppTheme.success
                : AppTheme.warning,
      ),
    );
  }

  void _showBlockDialog(BuildContext context, ThreatResponseProvider provider,
      String ip, String alertId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Block IP',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Block $ip from all network access?',
              style: const TextStyle(color: AppTheme.textSecondary)),
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
                Icon(Icons.warning_amber_rounded,
                    color: AppTheme.warning, size: 16),
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
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.borderPrimary)),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.isEmpty
                  ? 'Blocked manually'
                  : reasonController.text;
              Navigator.pop(ctx);
              final res = await provider.blockIP(ip, reason, alertId);
              if (context.mounted) {
                if (res['success'] == true) {
                  await StateCoordinator(context)
                      .afterThreatAction(ThreatActionType.block);
                }
                if (!context.mounted) return;
                _showActionResult(context, res);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Confirm Block',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
