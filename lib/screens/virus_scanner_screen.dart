import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/virus_scanner_provider.dart';
import '../models/scan_result.dart';

class VirusScannerScreen extends StatelessWidget {
  const VirusScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VirusScannerProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildUploadSection(context, provider),
                  if (provider.scanResult != null) ...[
                    const SizedBox(height: 24),
                    _buildResults(provider.scanResult!),
                  ],
                  const SizedBox(height: 24),
                  _buildInfoNote(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadSection(
      BuildContext context, VirusScannerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          const Text(
            'Virus & Malware Scanner',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a file or enter a URL to scan for threats',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppTheme.borderSecondary,
                  width: 2,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.upload,
                      color: AppTheme.primary, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Drop files here or click to browse',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text('Maximum file size: 256 MB',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Select File'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Or enter a URL to scan...',
              prefixIcon: const Icon(LucideIcons.link2, size: 20),
              filled: true,
              fillColor: AppTheme.borderPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderSecondary),
              ),
            ),
            onChanged: provider.setUrl,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isScanning ? null : provider.startScan,
              icon: Icon(LucideIcons.scanSearch, size: 24),
              label: Text(
                provider.isScanning ? 'Scanning...' : 'Scan Now',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ScanResult result) {
    final config = _getThreatConfig(result.threatLevel);
    return Container(
      padding: const EdgeInsets.all(32),
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
            children: [
              const Text('Scan Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              Text(result.fileName,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: config.bg,
              border: Border.all(color: config.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(config.icon, color: config.color, size: 48),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.threatLevel.name.toUpperCase()} RISK',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: config.color),
                        ),
                        Text(
                          'Detected by ${result.enginesDetected} of ${result.totalEngines} security engines',
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.borderPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: result.enginesDetected / result.totalEngines,
                    child: Container(
                      decoration: BoxDecoration(
                        color: config.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (result.detections.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Detections (${result.detections.length})',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ...result.detections.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.borderPrimary,
                    border: Border.all(color: AppTheme.borderSecondary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.triangleAlert,
                          color: AppTheme.warning, size: 16),
                      const SizedBox(width: 12),
                      Text(d,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 14)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Note: This scanner uses VirusTotal API. Connect your API key in Settings to enable real scanning.',
        style: TextStyle(fontSize: 14, color: AppTheme.info),
      ),
    );
  }

  ThreatConfig _getThreatConfig(ScanThreatLevel level) {
    switch (level) {
      case ScanThreatLevel.clean:
        return ThreatConfig(
          icon: LucideIcons.shield,
          color: AppTheme.success,
          bg: AppTheme.success.withOpacity(0.1),
          border: AppTheme.success.withOpacity(0.2),
        );
      case ScanThreatLevel.low:
        return ThreatConfig(
          icon: LucideIcons.shield,
          color: AppTheme.info,
          bg: AppTheme.info.withOpacity(0.1),
          border: AppTheme.info.withOpacity(0.2),
        );
      case ScanThreatLevel.medium:
        return ThreatConfig(
          icon: LucideIcons.triangleAlert,
          color: Colors.yellow.shade600,
          bg: Colors.yellow.shade600.withOpacity(0.1),
          border: Colors.yellow.shade600.withOpacity(0.2),
        );
      case ScanThreatLevel.high:
        return ThreatConfig(
          icon: LucideIcons.triangleAlert,
          color: AppTheme.warning,
          bg: AppTheme.warning.withOpacity(0.1),
          border: AppTheme.warning.withOpacity(0.2),
        );
      case ScanThreatLevel.critical:
        return ThreatConfig(
          icon: LucideIcons.circleX,
          color: AppTheme.error,
          bg: AppTheme.error.withOpacity(0.1),
          border: AppTheme.error.withOpacity(0.2),
        );
    }
  }
}

class ThreatConfig {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;

  ThreatConfig({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
  });
}
