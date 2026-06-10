import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/packet_tracing_provider.dart';
import '../models/packet.dart';

class PacketTracingScreen extends StatelessWidget {
  const PacketTracingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PacketTracingProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildControlBar(context, provider),
              const SizedBox(height: AppTheme.spacing16),
              _buildMainContent(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlBar(BuildContext context, PacketTracingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: provider.toggleCapturing,
                icon: Icon(
                  provider.isCapturing ? LucideIcons.pause : LucideIcons.play,
                  size: 20,
                ),
                label: Text(
                  provider.isCapturing ? 'Stop Capture' : 'Start Capture',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      provider.isCapturing ? AppTheme.error : AppTheme.primary,
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
              const Spacer(),
              Icon(LucideIcons.filter, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: AppTheme.spacing12),
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
              const SizedBox(width: AppTheme.spacing12),
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
            ],
          ),
        ],
      ),
    );
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

  Widget _buildMainContent(
      BuildContext context, PacketTracingProvider provider) {
    final isMobile = AppTheme.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildPacketList(provider),
          const SizedBox(height: AppTheme.spacing16),
          _buildDetailPanel(provider),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildPacketList(provider),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          flex: 1,
          child: _buildDetailPanel(provider),
        ),
      ],
    );
  }

  Widget _buildPacketList(PacketTracingProvider provider) {
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
                Text(
                  provider.isCapturing ? 'Capturing packets...' : 'Paused',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppTheme.borderPrimary),
              columns: const [
                DataColumn(
                  label: Text(
                    'IP ADDRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'PORT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'PROTOCOL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SIZE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TIME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ],
              rows: provider.packets.map((packet) {
                final isSelected = provider.selectedPacket?.id == packet.id;
                final badge = _getStatusBadge(packet.status);

                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (_) => provider.selectPacket(packet),
                  color: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppTheme.borderPrimary;
                    }
                    if (states.contains(MaterialState.hovered)) {
                      return AppTheme.borderPrimary;
                    }
                    return Colors.transparent;
                  }),
                  cells: [
                    DataCell(Text(
                      packet.ip,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    )),
                    DataCell(Text(
                      packet.port.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    )),
                    DataCell(Text(
                      packet.protocol,
                      style: const TextStyle(fontSize: 14),
                    )),
                    DataCell(Text(
                      packet.size,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badge.bg,
                          border: Border.all(color: badge.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          packet.status.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: badge.text,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      packet.timestamp,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Packet Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          if (provider.selectedPacket != null) ...[
            _buildDetailItem('Source IP', provider.selectedPacket!.ip),
            _buildDetailItem('Port', provider.selectedPacket!.port.toString()),
            _buildDetailItem('Protocol', provider.selectedPacket!.protocol),
            _buildDetailItem('Packet Size', provider.selectedPacket!.size),
            _buildDetailItem(
              'ML Classification',
              provider.selectedPacket!.status.name.toUpperCase(),
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
    );
  }

  Widget _buildDetailItem(String label, String value) {
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
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  StatusBadge _getStatusBadge(PacketStatus status) {
    switch (status) {
      case PacketStatus.normal:
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
    }
  }
}

class StatusBadge {
  final Color bg;
  final Color text;
  final Color border;

  StatusBadge({required this.bg, required this.text, required this.border});
}
