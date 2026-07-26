import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/report_summary.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.summary == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        if (provider.summary == null) {
          return _ErrorState(
            message: provider.error ?? 'No report data is available yet.',
            onRetry: provider.refresh,
          );
        }

        final summary = provider.summary!;
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: provider.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(provider: provider, summary: summary),
                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  _MessageBanner(
                    icon: LucideIcons.triangleAlert,
                    message: provider.error!,
                    color: AppTheme.warning,
                  ),
                ],
                if (summary.hasPartialSources ||
                    summary.messages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SourceStatus(summary: summary),
                ],
                const SizedBox(height: 24),
                _ExecutiveSummary(summary: summary),
                const SizedBox(height: 24),
                _SessionSummary(summary: summary),
                const SizedBox(height: 24),
                _ClassificationSection(summary: summary),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 760;
                    final severity = _SeveritySection(summary: summary);
                    final types = _ThreatTypesSection(summary: summary);
                    if (narrow) {
                      return Column(
                        children: [
                          severity,
                          const SizedBox(height: 16),
                          types,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: severity),
                        const SizedBox(width: 16),
                        Expanded(child: types),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _TopAttackers(summary: summary),
                const SizedBox(height: 24),
                _ResponseTimeline(summary: summary),
                const SizedBox(height: 24),
                _ExportPanel(provider: provider),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ReportsProvider provider;
  final ReportSummary summary;

  const _Header({required this.provider, required this.summary});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reports & Intelligence Center',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.timeframeLabel} · '
                  '${_monitoringLabel(summary.monitoringState)}'
                  '${summary.interfaceName == null ? '' : ' · Interface ${summary.interfaceName}'}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: provider.isRefreshing ? null : () => provider.refresh(),
            icon: provider.isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ClassificationSection extends StatelessWidget {
  final ReportSummary summary;

  const _ClassificationSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final distribution = summary.classificationDistribution;
    return _Panel(
      title: '${summary.timeframeLabel} Classification Distribution',
      child: distribution.total == 0
          ? const _NeutralEmpty(
              icon: LucideIcons.chartNoAxesColumn,
              message: 'No completed or partial classifications are available.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < 520
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 36) / 4;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Metric(
                      width: width,
                      label: 'Normal',
                      value: '${distribution['normal']}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Suspicious',
                      value: '${distribution['suspicious']}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Malicious',
                      value: '${distribution['malicious']}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Unknown',
                      value: '${distribution['unknown']}',
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ExecutiveSummary extends StatelessWidget {
  final ReportSummary summary;

  const _ExecutiveSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final session = summary.session;
    String text;
    if (summary.timeframe == 'current_session') {
      text =
          'Monitoring is active. This session has captured ${session.captured} '
          'packets and analyzed ${session.analyzed}; ${session.pending} remain '
          'pending.';
    } else if (summary.timeframe == 'last_session') {
      text =
          'Monitoring is inactive. The last session captured ${session.captured} '
          'packets and analyzed ${session.analyzed}. These retained values do '
          'not describe current network safety.';
    } else {
      text =
          'Monitoring is inactive and no capture-session data is available yet.';
    }
    return _Panel(
      title: 'Executive Summary',
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  final ReportSummary summary;

  const _SessionSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final session = summary.session;
    final prefix = summary.timeframe == 'last_session'
        ? 'Last Session'
        : summary.timeframe == 'current_session'
            ? 'Current Session'
            : 'Session';
    return _Panel(
      title: '$prefix Analysis',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth < 520
              ? constraints.maxWidth
              : constraints.maxWidth < 900
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                width: cardWidth,
                label: '$prefix Captured',
                value: '${session.captured}',
              ),
              _Metric(
                width: cardWidth,
                label: '$prefix Analyzed',
                value: '${session.analyzed}',
              ),
              _Metric(
                width: cardWidth,
                label: '$prefix Completion',
                value: '${session.completionPercentage.toStringAsFixed(1)}%',
              ),
              _Metric(
                width: cardWidth,
                label: '$prefix Threat Score',
                value: session.threatScore == null
                    ? 'N/A'
                    : '${session.threatScore!.toStringAsFixed(1)} / 100',
              ),
              _Metric(
                width: cardWidth,
                label: 'Complete',
                value: '${session.complete}',
              ),
              _Metric(
                width: cardWidth,
                label: 'Partial',
                value: '${session.partial}',
              ),
              _Metric(
                width: cardWidth,
                label: 'Failed / Deferred',
                value: '${session.failed} / ${session.deferred}',
              ),
              _Metric(
                width: cardWidth,
                label: 'Pending / Not analyzed',
                value: '${session.pending} / ${session.notAnalyzed}',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SeveritySection extends StatelessWidget {
  final ReportSummary summary;

  const _SeveritySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final distribution = summary.severityDistribution;
    if (summary.sourceStatus.alerts == 'unavailable') {
      return const _Panel(
        title: 'Severity Distribution · Recent Historical Data',
        child: _NeutralEmpty(
          icon: LucideIcons.databaseZap,
          message: 'Alert severity data is temporarily unavailable.',
        ),
      );
    }
    if (distribution.total == 0) {
      return const _Panel(
        title: 'Severity Distribution · Recent Historical Data',
        child: _NeutralEmpty(
          icon: LucideIcons.shieldQuestion,
          message: 'No analyzed threat data is available for this session.',
        ),
      );
    }
    const colors = {
      'low': AppTheme.info,
      'medium': AppTheme.warning,
      'high': Colors.orange,
      'critical': AppTheme.error,
      'unknown': AppTheme.textTertiary,
    };
    return _Panel(
      title: 'Severity Distribution · Recent Historical Data',
      child: Column(
        children: distribution.values.entries.map((entry) {
          final fraction = entry.value / distribution.total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    _title(entry.key),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: AppTheme.borderPrimary,
                      valueColor: AlwaysStoppedAnimation(colors[entry.key]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThreatTypesSection extends StatelessWidget {
  final ReportSummary summary;

  const _ThreatTypesSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Top Threat Types · Recent Historical Data',
      child: summary.topThreatTypes.isEmpty
          ? const _NeutralEmpty(
              icon: LucideIcons.searchX,
              message: 'No threat-type evidence is available.',
            )
          : Column(
              children: summary.topThreatTypes
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.threatType,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      trailing: Text(
                        '${item.count}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _TopAttackers extends StatelessWidget {
  final ReportSummary summary;

  const _TopAttackers({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Top Attackers · Recent Historical Data',
      child: summary.topAttackers.isEmpty
          ? const _NeutralEmpty(
              icon: LucideIcons.userRoundSearch,
              message: 'No attacker evidence is available.',
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: summary.topAttackers
                  .map(
                    (item) => Container(
                      width: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgPrimary,
                        border: Border.all(color: AppTheme.borderPrimary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.sourceIp,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.count} alert(s) · '
                            '${item.highestSeverity ?? 'Unknown'} · '
                            '${item.country ?? 'Country unavailable'}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ResponseTimeline extends StatelessWidget {
  final ReportSummary summary;

  const _ResponseTimeline({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Response Timeline Summary · Recent Historical Data',
      child: summary.responseTimeline.isEmpty
          ? const _NeutralEmpty(
              icon: LucideIcons.clock3,
              message: 'No recorded response actions are available.',
            )
          : Column(
              children: summary.responseTimeline.take(12).map((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    LucideIcons.shieldCheck,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    item.action,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    '${item.target ?? 'Unknown target'} · '
                    '${item.status ?? 'Unknown status'}'
                    '${item.analyst == null ? '' : ' · ${item.analyst}'}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: item.timestamp == null
                      ? null
                      : Text(
                          item.timestamp!,
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                );
              }).toList(),
            ),
    );
  }
}

class _ExportPanel extends StatelessWidget {
  final ReportsProvider provider;

  const _ExportPanel({required this.provider});

  Future<void> _runExport(
    BuildContext context,
    ReportExportKind kind,
  ) async {
    final outcome = await provider.export(kind);
    if (!context.mounted || outcome.status == ReportExportStatus.busy) {
      return;
    }
    final isFailure = outcome.status == ReportExportStatus.failed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: isFailure ? AppTheme.error : AppTheme.bgSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Export & Downloads',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ExportButton(
            label: 'Download PDF',
            icon: LucideIcons.fileText,
            kind: ReportExportKind.pdf,
            provider: provider,
            onPressed: () => _runExport(context, ReportExportKind.pdf),
          ),
          _ExportButton(
            label: 'Export JSON',
            icon: LucideIcons.code,
            kind: ReportExportKind.json,
            provider: provider,
            onPressed: () => _runExport(context, ReportExportKind.json),
          ),
          _ExportButton(
            label: 'CSV: Alerts',
            icon: LucideIcons.table,
            kind: ReportExportKind.alertsCsv,
            provider: provider,
            onPressed: () => _runExport(context, ReportExportKind.alertsCsv),
          ),
          _ExportButton(
            label: 'CSV: Actions',
            icon: LucideIcons.table,
            kind: ReportExportKind.actionsCsv,
            provider: provider,
            onPressed: () => _runExport(context, ReportExportKind.actionsCsv),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final ReportExportKind kind;
  final ReportsProvider provider;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.kind,
    required this.provider,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final loading = provider.isExporting(kind);
    return ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.borderPrimary,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _SourceStatus extends StatelessWidget {
  final ReportSummary summary;

  const _SourceStatus({required this.summary});

  @override
  Widget build(BuildContext context) {
    final unavailable = <String>[
      if (summary.sourceStatus.capture == 'unavailable') 'capture',
      if (summary.sourceStatus.alerts == 'unavailable') 'alerts',
      if (summary.sourceStatus.actions == 'unavailable') 'actions',
      if (summary.sourceStatus.intelligence == 'unavailable') 'intelligence',
    ];
    final parts = <String>[
      if (unavailable.isNotEmpty)
        'Unavailable sources: ${unavailable.join(', ')}.',
      ...summary.messages,
    ];
    return _MessageBanner(
      icon: LucideIcons.info,
      message: parts.join(' '),
      color: AppTheme.warning,
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _MessageBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
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
}

class _Metric extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _Metric({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgPrimary,
          border: Border.all(color: AppTheme.borderPrimary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Panel({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
          ],
          child,
        ],
      ),
    );
  }
}

class _NeutralEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _NeutralEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textTertiary, size: 38),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function({bool silent}) onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.fileWarning,
              color: AppTheme.textTertiary,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _monitoringLabel(String state) {
  switch (state) {
    case 'running':
      return 'Monitoring active';
    case 'stopping':
      return 'Monitoring stopping';
    default:
      return 'Monitoring inactive';
  }
}

String _title(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
