import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/packet_tracing_provider.dart';
import '../providers/capture_capability_provider.dart';
import '../models/packet.dart';
import 'capture_onboarding_screen.dart';

enum _CaptureConfigurationAction { changeInterface, diagnostics, reset }

class PacketTracingScreen extends StatefulWidget {
  const PacketTracingScreen({super.key});

  @override
  State<PacketTracingScreen> createState() => _PacketTracingScreenState();
}

class _PacketTracingScreenState extends State<PacketTracingScreen> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PacketTracingProvider, CaptureCapabilityProvider>(
      builder: (context, provider, capabilityProvider, _) {
        final result = capabilityProvider.capabilityResult;

        if (!capabilityProvider.setupPreferenceLoaded || result == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // A stored setup is trusted only while current dependency, permission,
        // and interface checks remain valid.
        if (!capabilityProvider.isSetupValid) {
          return CaptureOnboardingScreen(
            onReady: () {
              // Once ready, refresh state to show PacketTracing
              setState(() {});
            },
          );
        }

        return Column(
          children: [
            _buildControlBar(context, provider, capabilityProvider),
            if (provider.captureError != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              _buildErrorBanner(
                provider.captureError!,
                label: 'Capture error',
              ),
            ] else if (provider.error != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              _buildErrorBanner(
                provider.error!,
                label: 'Packet history',
              ),
            ],
            const SizedBox(height: AppTheme.spacing16),
            Expanded(
              child: _buildMainContent(
                context,
                provider,
                capabilityProvider,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorBanner(String message, {required String label}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.12),
        border: Border.all(color: AppTheme.error.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.triangleAlert,
              color: AppTheme.error, size: 18),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              '$label: $message',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, PacketTracingProvider provider,
      CaptureCapabilityProvider capabilityProvider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.spacing12,
            runSpacing: AppTheme.spacing12,
            children: [
              ElevatedButton.icon(
                onPressed: provider.isTransitioning ||
                        provider.captureState == CaptureState.unavailable
                    ? null
                    : () => provider.toggleCapturing(
                          interfaceName:
                              capabilityProvider.selectedInterfaceId ??
                                  capabilityProvider
                                      .capabilityResult?.recommendedInterface ??
                                  'en0',
                        ),
                icon: Icon(
                  provider.isCapturing ? LucideIcons.pause : LucideIcons.play,
                  size: 20,
                ),
                label: Text(
                  provider.captureState == CaptureState.starting
                      ? 'Starting...'
                      : provider.captureState == CaptureState.stopping
                          ? 'Stopping...'
                          : provider.isCapturing
                              ? 'Stop Capture'
                              : 'Start Capture',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isCapturing
                      ? AppTheme.warning
                      : AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                    vertical: AppTheme.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeInterfaceLabel(capabilityProvider),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  PopupMenuButton<_CaptureConfigurationAction>(
                    tooltip: 'Capture configuration',
                    icon: const Icon(LucideIcons.settings, size: 18),
                    onSelected: (action) async {
                      switch (action) {
                        case _CaptureConfigurationAction.changeInterface:
                          await capabilityProvider.reconfigure();
                          break;
                        case _CaptureConfigurationAction.diagnostics:
                          await capabilityProvider.runDiagnostics();
                          break;
                        case _CaptureConfigurationAction.reset:
                          await capabilityProvider.resetSetup();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _CaptureConfigurationAction.changeInterface,
                        child: Text('Change interface'),
                      ),
                      PopupMenuItem(
                        value: _CaptureConfigurationAction.diagnostics,
                        child: Text('Run diagnostics'),
                      ),
                      PopupMenuItem(
                        value: _CaptureConfigurationAction.reset,
                        child: Text('Reset capture setup/consent'),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.spacing12,
                runSpacing: AppTheme.spacing12,
                children: [
                  Icon(LucideIcons.filter,
                      color: AppTheme.textSecondary, size: 20),
                  _buildDropdown(
                    value: provider.protocolFilter,
                    items: ['all', 'http', 'ssh', 'ftp', 'dns'],
                    labels: {
                      'all': 'All Protocols',
                      'http': 'HTTP/HTTPS',
                      'ssh': 'SSH',
                      'ftp': 'FTP',
                      'dns': 'DNS',
                    },
                    onChanged: provider.setProtocolFilter,
                  ),
                  _buildDropdown(
                    value: provider.riskFilter,
                    items: ['all', 'normal', 'suspicious', 'malicious'],
                    labels: {
                      'all': 'All Risk Levels',
                      'normal': 'Normal',
                      'suspicious': 'Suspicious',
                      'malicious': 'Malicious',
                    },
                    onChanged: provider.setRiskFilter,
                  ),
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: TextField(
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search IP or Port...',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(LucideIcons.search,
                            size: 16, color: AppTheme.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        filled: true,
                        fillColor: AppTheme.bgPrimary,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide:
                              const BorderSide(color: AppTheme.borderPrimary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide:
                              const BorderSide(color: AppTheme.borderPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _activeInterfaceLabel(CaptureCapabilityProvider provider) {
    final result = provider.capabilityResult;
    final selectedId =
        provider.selectedInterfaceId ?? result?.recommendedInterface;
    if (selectedId == null || result == null) return 'Interface unavailable';
    for (final item in result.interfaces) {
      if (item.id == selectedId) {
        return 'Interface: ${item.displayName} · ${item.id}';
      }
    }
    return 'Interface: $selectedId';
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Map<String, String> labels,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.borderPrimary,
        border: Border.all(color: AppTheme.borderSecondary),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.bgSecondary,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(labels[item] ?? item),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, PacketTracingProvider provider,
      CaptureCapabilityProvider capabilityProvider) {
    final isMobile = AppTheme.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildPacketList(provider, capabilityProvider),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Expanded(flex: 2, child: _buildDetailPanel(provider)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildPacketList(provider, capabilityProvider),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          flex: 1,
          child: _buildDetailPanel(provider),
        ),
      ],
    );
  }

  Widget _buildPacketList(PacketTracingProvider provider,
      CaptureCapabilityProvider capabilityProvider) {
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
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Packet Stream',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildCaptureStatusChip(provider.captureState),
                        ],
                      ),
                    ),
                    Text(
                      provider.totalPacketsReceived > provider.packets.length
                          ? 'Displaying ${provider.packets.length} of ${provider.totalPacketsReceived} packets'
                          : '${provider.packets.length} packets',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.captureState == CaptureState.stopped &&
                    provider.packets.isEmpty
                ? _buildStoppedEmptyState(provider, capabilityProvider)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          scrollDirection: Axis.vertical,
                          child: Scrollbar(
                            controller: _horizontalController,
                            notificationPredicate: (notification) =>
                                notification.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                      AppTheme.borderPrimary),
                                  columns: [
                                    DataColumn(
                                      label: SizedBox(
                                        width: 120,
                                        child: _colHeader('IP ADDRESS'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 60,
                                        child: _colHeader('PORT'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 80,
                                        child: _colHeader('PROTOCOL'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 60,
                                        child: _colHeader('SIZE'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: _colHeader('STATUS'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 80,
                                        child: _colHeader('TIME'),
                                      ),
                                    ),
                                  ],
                                  rows: provider.packets.map((packet) {
                                    final isSelected =
                                        provider.selectedPacketId ==
                                            packet.stableId;
                                    final badge = _getStatusBadge(packet);

                                    return DataRow(
                                      key: ValueKey(packet.stableId),
                                      selected: isSelected,
                                      onSelectChanged: (selected) {
                                        if (selected == true) {
                                          provider.selectPacketById(
                                              packet.stableId);
                                        } else {
                                          provider.clearSelection();
                                        }
                                      },
                                      color: MaterialStateProperty.resolveWith(
                                          (states) {
                                        if (states
                                            .contains(MaterialState.selected)) {
                                          return AppTheme.borderPrimary;
                                        }
                                        if (states
                                            .contains(MaterialState.hovered)) {
                                          return AppTheme.borderPrimary;
                                        }
                                        return Colors.transparent;
                                      }),
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: 120,
                                            child: Tooltip(
                                              message: packet.ip,
                                              child: Text(
                                                packet.ip,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              packet.port.toString(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 80,
                                            child: _buildProtocolBadge(
                                                packet.protocol),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              packet.size,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 100,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: badge.bg,
                                                border: Border.all(
                                                    color: badge.border),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                packet.mlClassification,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: badge.text,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              packet.timestamp,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoppedEmptyState(
    PacketTracingProvider provider,
    CaptureCapabilityProvider capabilityProvider,
  ) {
    final result = capabilityProvider.capabilityResult;
    final selectedId = capabilityProvider.selectedInterfaceId ??
        result?.recommendedInterface ??
        'en0';
    var displayName = selectedId;
    if (result != null) {
      for (final item in result.interfaces) {
        if (item.id == selectedId) {
          displayName = item.displayName;
          break;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.network,
                    size: 44,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  const Text(
                    'Packet capture is stopped',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Start capture to monitor traffic on $displayName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  ElevatedButton.icon(
                    onPressed: () => provider.toggleCapturing(
                      interfaceName: selectedId,
                    ),
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: const Text('Start Capture'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppTheme.textTertiary,
      ),
    );
  }

  Widget _buildDetailPanel(PacketTracingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Packet Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (provider.selectedPacket != null)
                  IconButton(
                    icon: const Icon(LucideIcons.x,
                        size: 20, color: AppTheme.textSecondary),
                    onPressed: provider.clearSelection,
                    tooltip: 'Clear selection',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),
            if (provider.selectedPacket != null) ...[
              _buildDetailItem('Source IP', provider.selectedPacket!.ip),
              _buildDetailItem(
                  'Port', provider.selectedPacket!.port.toString()),
              _buildDetailItem('Protocol', provider.selectedPacket!.protocol),
              _buildDetailItem('Packet Size', provider.selectedPacket!.size),
              _buildDetailItem(
                'ML Classification',
                provider.selectedPacket!.mlClassification,
                textColor: _getClassificationColor(
                    provider.selectedPacket!.mlClassification),
              ),
              _buildDetailItem(
                'Decision Severity',
                provider.selectedPacket!.decisionSeverity,
                textColor: _getSeverityColor(
                    provider.selectedPacket!.decisionSeverity),
              ),
              _buildDetailItem(
                'Final Risk Score',
                provider.selectedPacket!.finalRiskScore,
                textColor: AppTheme.textPrimary,
              ),
              _buildDetailItem('Timestamp', provider.selectedPacket!.timestamp),
              const Divider(color: AppTheme.borderPrimary, height: 32),
              const Text(
                'Raw Packet Data',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.borderPrimary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Text(
                  '45 00 00 3c 1c 46 40 00 40 06 b1 e6 ac 10 0a 63...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(64.0),
                  child: Text(
                    'Select a packet to view details',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  textColor != null ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolBadge(String protocol) {
    Color color;
    switch (protocol.toUpperCase()) {
      case 'HTTP':
      case 'HTTPS':
        color = Colors.blue;
        break;
      case 'SSH':
        color = Colors.purple;
        break;
      case 'FTP':
        color = Colors.orange;
        break;
      case 'DNS':
        color = Colors.teal;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        protocol.toUpperCase(),
        style:
            TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCaptureStatusChip(CaptureState state) {
    Color color;
    String label;
    IconData icon;

    switch (state) {
      case CaptureState.running:
        color = AppTheme.success;
        label = 'Capturing';
        icon = Icons.circle;
        break;
      case CaptureState.stopped:
        color = AppTheme.textSecondary;
        label = 'Stopped';
        icon = Icons.stop_circle;
        break;
      case CaptureState.starting:
        color = AppTheme.warning;
        label = 'Starting...';
        icon = Icons.hourglass_empty;
        break;
      case CaptureState.stopping:
        color = AppTheme.warning;
        label = 'Stopping...';
        icon = Icons.hourglass_empty;
        break;
      case CaptureState.error:
        color = AppTheme.error;
        label = 'Error';
        icon = Icons.error_outline;
        break;
      case CaptureState.unavailable:
        color = AppTheme.textTertiary;
        label = 'Unavailable';
        icon = Icons.cloud_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getClassificationColor(String classification) {
    switch (classification) {
      case 'BENIGN':
        return AppTheme.success;
      case 'SUSPICIOUS':
        return AppTheme.warning;
      case 'MALICIOUS':
        return AppTheme.error;
      default:
        return AppTheme.textPrimary;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'INFO':
        return Colors.blue;
      case 'LOW':
        return Colors.blueGrey;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.deepOrange;
      case 'CRITICAL':
        return AppTheme.error;
      default:
        return AppTheme.textPrimary;
    }
  }

  StatusBadge _getStatusBadge(Packet packet) {
    if (packet.analysisStatus != 'complete') {
      return StatusBadge(
        bg: AppTheme.textTertiary.withOpacity(0.1),
        text: AppTheme.textTertiary,
        border: AppTheme.textTertiary.withOpacity(0.2),
      );
    }
    switch (packet.status) {
      case PacketStatus.benign:
        return StatusBadge(
          bg: AppTheme.success.withOpacity(0.1),
          text: AppTheme.success,
          border: AppTheme.success.withOpacity(0.2),
        );
      case PacketStatus.suspicious:
        return StatusBadge(
          bg: AppTheme.warning.withOpacity(0.1),
          text: AppTheme.warning,
          border: AppTheme.warning.withOpacity(0.2),
        );
      case PacketStatus.malicious:
        return StatusBadge(
          bg: AppTheme.error.withOpacity(0.1),
          text: AppTheme.error,
          border: AppTheme.error.withOpacity(0.2),
        );
      case PacketStatus.unknown:
        return StatusBadge(
          bg: AppTheme.textTertiary.withOpacity(0.1),
          text: AppTheme.textTertiary,
          border: AppTheme.textTertiary.withOpacity(0.2),
        );
    }
  }
}

class StatusBadge {
  final Color bg;
  final Color text;
  final Color border;

  StatusBadge({required this.bg, required this.text, required this.border});
}
