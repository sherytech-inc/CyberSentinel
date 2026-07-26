import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/firewall_action_model.dart';
import '../models/firewall_log.dart';
import '../providers/firewall_actions_provider.dart';
import '../providers/firewall_logs_provider.dart';

class FirewallLogsScreen extends StatefulWidget {
  const FirewallLogsScreen({super.key});

  @override
  State<FirewallLogsScreen> createState() => _FirewallLogsScreenState();
}

class _FirewallLogsScreenState extends State<FirewallLogsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirewallLogsProvider, FirewallActionsProvider>(
      builder: (context, logs, actions, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _topBar(logs, actions),
              const SizedBox(height: AppTheme.spacing16),
              _tabs(),
              const SizedBox(height: AppTheme.spacing16),
              if (_selectedTab == 0) _analysis(logs) else _actions(actions),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar(FirewallLogsProvider logs, FirewallActionsProvider actions) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: _panelDecoration(),
      child: LayoutBuilder(builder: (context, constraints) {
        return Wrap(
          spacing: AppTheme.spacing12,
          runSpacing: AppTheme.spacing12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firewall Log Analysis',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Analyze supported operating-system firewall logs locally.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            if (_selectedTab == 0)
              ElevatedButton.icon(
                key: const Key('select-firewall-file'),
                onPressed: logs.isLoading ? null : () => _selectFile(logs),
                icon: const Icon(LucideIcons.fileUp, size: 17),
                label: const Text('Select log file'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              )
            else
              IconButton(
                onPressed: actions.isLoading
                    ? null
                    : () => actions.fetchActions(refresh: true),
                icon: const Icon(LucideIcons.refreshCw),
                tooltip: 'Refresh recorded actions',
              ),
          ],
        );
      }),
    );
  }

  Future<void> _selectFile(FirewallLogsProvider provider) async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['log', 'txt', 'csv'],
        withData: true,
      );
      if (!mounted || selection == null || selection.files.isEmpty) return;
      final file = selection.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _safeSnack('The selected file could not be read.');
        return;
      }
      provider.selectFile(file.name, bytes);
    } catch (_) {
      if (mounted) _safeSnack('The file picker is temporarily unavailable.');
    }
  }

  void _safeSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.error,
    ));
  }

  Widget _tabs() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(
              value: 0,
              icon: Icon(LucideIcons.fileSearch, size: 16),
              label: Text('Log Analysis')),
          ButtonSegment(
              value: 1,
              icon: Icon(LucideIcons.history, size: 16),
              label: Text('Recorded SOC Actions')),
        ],
        selected: {_selectedTab},
        onSelectionChanged: (selection) =>
            setState(() => _selectedTab = selection.first),
      ),
    );
  }

  Widget _analysis(FirewallLogsProvider provider) {
    if (provider.state == FirewallAnalysisState.noFile) {
      return _emptyState(
        LucideIcons.fileSearch,
        'No firewall log selected',
        'Select a Windows Firewall, UFW, iptables, macOS pf, or mapped CSV log to analyze it locally.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fileCard(provider),
        if (provider.message != null) ...[
          const SizedBox(height: AppTheme.spacing12),
          _messageCard(provider),
        ],
        if (provider.result != null) ...[
          const SizedBox(height: AppTheme.spacing16),
          _summary(provider.result!),
          const SizedBox(height: AppTheme.spacing16),
          _filters(provider),
          const SizedBox(height: AppTheme.spacing16),
          _eventWorkspace(provider),
        ],
      ],
    );
  }

  Widget _fileCard(FirewallLogsProvider provider) {
    final busy = provider.isLoading;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: AppTheme.spacing12,
        runSpacing: AppTheme.spacing12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.fileText,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: AppTheme.spacing12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.filename ?? 'Selected log',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        busy
                            ? provider.state == FirewallAnalysisState.uploading
                                ? 'Uploading securely…'
                                : 'Analyzing locally…'
                            : 'Ready for read-only analysis',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppTheme.spacing8,
            children: [
              if (busy)
                OutlinedButton(
                  key: const Key('cancel-firewall-analysis'),
                  onPressed: provider.cancel,
                  child: const Text('Cancel'),
                )
              else
                ElevatedButton.icon(
                  key: const Key('analyze-firewall-file'),
                  onPressed: provider.canAnalyze ? provider.analyze : null,
                  icon: const Icon(LucideIcons.search, size: 16),
                  label: const Text('Analyze'),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageCard(FirewallLogsProvider provider) {
    final warning = provider.state == FirewallAnalysisState.partial;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color:
            (warning ? AppTheme.warning : AppTheme.error).withValues(alpha: .1),
        border: Border.all(
            color: (warning ? AppTheme.warning : AppTheme.error)
                .withValues(alpha: .5)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(warning ? LucideIcons.triangleAlert : LucideIcons.circleAlert,
              color: warning ? AppTheme.warning : AppTheme.error, size: 18),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
              child: Text(provider.message!,
                  style: const TextStyle(color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _summary(FirewallAnalysisResult result) {
    final summary = result.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected format: ${_formatLabel(summary.detectedFormat)}',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing12,
          runSpacing: AppTheme.spacing12,
          children: [
            _metric('Total lines', summary.totalLines),
            _metric('Parsed events', summary.parsedEvents),
            _metric('Allowed', summary.allowedCount),
            _metric('Denied / dropped', summary.deniedDroppedCount),
            _metric('Partial', summary.partialEvents),
            _metric('Failed lines', summary.failedLines),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final panels = [
            _distribution(
                'Protocols',
                summary.protocolDistribution
                    .map((item) => '${item.value}: ${item.count}')
                    .toList()),
            _distribution(
                'Top source IPs',
                summary.topSourceIps
                    .map((item) => '${item.value}: ${item.count}')
                    .toList()),
            _distribution(
                'Top destination ports',
                summary.topDestinationPorts
                    .map((item) => '${item.port}: ${item.count}')
                    .toList()),
          ];
          return narrow
              ? Column(
                  children: panels
                      .map((panel) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: panel,
                          ))
                      .toList())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: panels
                      .map((panel) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: panel,
                            ),
                          ))
                      .toList(),
                );
        }),
      ],
    );
  }

  Widget _metric(String label, int value) => Container(
        width: 150,
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: _panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('$value',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _distribution(String title, List<String> rows) => Container(
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: _panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('No data available',
                  style: TextStyle(color: AppTheme.textSecondary))
            else
              ...rows.take(5).map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(row,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textSecondary)),
                  )),
          ],
        ),
      );

  Widget _filters(FirewallLogsProvider provider) {
    final protocols = provider.logs
        .map((event) => event.protocol)
        .whereType<String>()
        .toSet();
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: AppTheme.spacing8,
        runSpacing: AppTheme.spacing8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _dropdown(
              'Action',
              provider.actionFilter,
              const ['allow', 'deny', 'drop', 'reject', 'unknown'],
              (value) => provider.setFilters(action: value)),
          _dropdown('Protocol', provider.protocolFilter, protocols.toList(),
              (value) => provider.setFilters(protocol: value)),
          _dropdown(
              'Direction',
              provider.directionFilter,
              const ['inbound', 'outbound', 'unknown'],
              (value) => provider.setFilters(direction: value)),
          _dropdown(
              'Parse status',
              provider.parseStatusFilter,
              const ['complete', 'partial'],
              (value) => provider.setFilters(parseStatus: value)),
          _filterField(
              'Source IP', (value) => provider.setFilters(source: value)),
          _filterField('Destination IP',
              (value) => provider.setFilters(destination: value)),
          _filterField('Port', (value) => provider.setFilters(port: value),
              numeric: true),
          TextButton.icon(
            onPressed: provider.clearFilters,
            icon: const Icon(LucideIcons.x, size: 15),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> values,
      ValueChanged<String?> onChanged) {
    final sorted = values.toSet().toList()..sort();
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: sorted
            .map((item) =>
                DropdownMenuItem(value: item, child: Text(item.toUpperCase())))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _filterField(String label, ValueChanged<String> onChanged,
      {bool numeric = false}) {
    return SizedBox(
      width: 160,
      child: TextField(
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: onChanged,
      ),
    );
  }

  Widget _eventWorkspace(FirewallLogsProvider provider) {
    return LayoutBuilder(builder: (context, constraints) {
      final table = _eventTable(provider);
      final details = _details(provider.selectedEvent);
      if (constraints.maxWidth < 900) {
        return Column(children: [
          table,
          const SizedBox(height: AppTheme.spacing12),
          details,
        ]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: table),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(flex: 2, child: details),
        ],
      );
    });
  }

  Widget _eventTable(FirewallLogsProvider provider) {
    final events = provider.filteredLogs;
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Text(
              '${events.length} visible event${events.length == 1 ? '' : 's'}',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacing32),
              child: Center(
                  child: Text('No events match the current filters.',
                      style: TextStyle(color: AppTheme.textSecondary))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('Line')),
                  DataColumn(label: Text('Action')),
                  DataColumn(label: Text('Protocol')),
                  DataColumn(label: Text('Source')),
                  DataColumn(label: Text('Destination')),
                  DataColumn(label: Text('Status')),
                ],
                rows: events
                    .map((event) => DataRow(
                          key: ValueKey(event.id),
                          selected: provider.selectedEvent?.id == event.id,
                          onSelectChanged: (_) => provider.selectEvent(event),
                          cells: [
                            DataCell(Text('${event.rawLineNumber}')),
                            DataCell(Text(event.action.toUpperCase())),
                            DataCell(
                                Text(event.protocol?.toUpperCase() ?? '—')),
                            DataCell(Text(
                                _endpoint(event.sourceIp, event.sourcePort))),
                            DataCell(Text(_endpoint(
                                event.destinationIp, event.destinationPort))),
                            DataCell(Text(event.parseStatus.toUpperCase())),
                          ],
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _details(FirewallLog? event) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: _panelDecoration(),
      child: event == null
          ? const Center(
              child: Text('Select an event to view normalized details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Event details',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: AppTheme.spacing12),
                _detail('Event ID', event.id),
                _detail(
                    'Timestamp',
                    event.timestamp == null
                        ? 'Unavailable'
                        : DateFormat('yyyy-MM-dd HH:mm:ss')
                            .format(event.timestamp!.toLocal())),
                _detail('Action', event.action),
                _detail('Direction', event.direction),
                _detail('Interface', event.interfaceName ?? 'Unavailable'),
                _detail('Protocol', event.protocol ?? 'Unavailable'),
                _detail('Source', _endpoint(event.sourceIp, event.sourcePort)),
                _detail('Destination',
                    _endpoint(event.destinationIp, event.destinationPort)),
                _detail(
                    'Packet size',
                    event.packetSize == null
                        ? 'Unavailable'
                        : '${event.packetSize} bytes'),
                _detail('Flags', event.flags ?? 'Unavailable'),
                _detail('Rule', event.rule ?? 'Unavailable'),
                if (event.messages.isNotEmpty)
                  _detail('Parser note', event.messages.join(' ')),
              ],
            ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 105,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(color: AppTheme.textPrimary))),
          ],
        ),
      );

  Widget _actions(FirewallActionsProvider provider) {
    if (provider.isLoading && provider.actions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.actions.isEmpty) {
      return _emptyState(
        LucideIcons.history,
        'No recorded SOC actions',
        'Actions recorded through Threat Response will appear here. This screen does not enforce firewall changes.',
      );
    }
    return Container(
      decoration: _panelDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('IP')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Source')),
            DataColumn(label: Text('Status')),
          ],
          rows: provider.actions.map(_actionRow).toList(),
        ),
      ),
    );
  }

  DataRow _actionRow(FirewallActionModel action) => DataRow(
        key: ValueKey(action.id),
        cells: [
          DataCell(Text(DateFormat('MMM d, HH:mm').format(action.createdAt))),
          DataCell(Text(action.ip)),
          DataCell(Text(action.action)),
          DataCell(Text(action.source)),
          DataCell(Text(action.enforced ? 'Enforced' : 'Recorded only')),
        ],
      );

  Widget _emptyState(IconData icon, String title, String subtitle) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacing48, horizontal: AppTheme.spacing24),
        decoration: _panelDecoration(),
        child: Column(
          children: [
            Icon(icon, size: 42, color: AppTheme.textTertiary),
            const SizedBox(height: AppTheme.spacing12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      );

  BoxDecoration _panelDecoration() => BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      );

  String _formatLabel(String value) =>
      {
        'windows_firewall': 'Windows Firewall',
        'ufw': 'UFW',
        'iptables': 'iptables',
        'macos_pf': 'macOS pf',
        'generic_csv': 'Mapped CSV',
      }[value] ??
      value;

  String _endpoint(String? ip, int? port) {
    if (ip == null) return 'Unavailable';
    return port == null ? ip : '$ip:$port';
  }
}
