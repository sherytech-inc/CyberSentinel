import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
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
                  if (provider.error != null) ...[
                    const SizedBox(height: 24),
                    _buildError(provider.error!),
                  ] else if (provider.scanResult != null) ...[
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

  // ── State for Tabs ──────────────────────────────────────────────────────────
  
  // We'll manage the text controllers here for simplicity.
  // The actual state update is handled by the provider.

  // ── Upload Section ─────────────────────────────────────────────────────────

  Widget _buildUploadSection(
      BuildContext context, VirusScannerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const Text(
              'Virus & Malware Scanner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan a URL, SHA-256 hash, or file for threats',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            
            TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(icon: Icon(LucideIcons.link2), text: 'URL'),
                Tab(icon: Icon(LucideIcons.hash), text: 'Hash'),
                Tab(icon: Icon(LucideIcons.fileSearch), text: 'File'),
              ],
              onTap: (index) {
                provider.clearResults();
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200, // Enough height for the tab content
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildUrlTab(context, provider),
                  _buildHashTab(context, provider),
                  _buildFileTab(context, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTab(BuildContext context, VirusScannerProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter a URL...',
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
            onPressed: provider.isScanning
                ? null
                : () => _handleScan(context, provider, 'url'),
            icon: const Icon(LucideIcons.scanSearch, size: 24),
            label: Text(
              provider.isScanning ? 'Scanning...' : 'Scan URL',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHashTab(BuildContext context, VirusScannerProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter SHA-256 hash...',
            prefixIcon: const Icon(LucideIcons.hash, size: 20),
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
            onPressed: provider.isScanning
                ? null
                : () => _handleScan(context, provider, 'hash'),
            icon: const Icon(LucideIcons.scanSearch, size: 24),
            label: Text(
              provider.isScanning ? 'Scanning...' : 'Scan Hash',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileTab(BuildContext context, VirusScannerProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderSecondary, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.borderPrimary.withOpacity(0.5),
          ),
          child: const Center(
            child: Text(
              'Click below to upload a file for hash analysis',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: provider.isScanning
                ? null
                : () => _handleFileScan(context, provider),
            icon: const Icon(LucideIcons.fileUp, size: 24),
            label: Text(
              provider.isScanning ? 'Uploading & Scanning...' : 'Choose File',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _handleScan(BuildContext context, VirusScannerProvider provider, String type) {
    final hasUrl = provider.url.trim().isNotEmpty;

    if (!hasUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.triangleAlert, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Please enter a ${type == 'url' ? 'URL' : 'hash'} before scanning.'),
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

    provider.startScan();
  }

  Future<void> _handleFileScan(BuildContext context, VirusScannerProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await provider.startFileScan(file.name, file.bytes!);
        } else {
          throw Exception('File data could not be read.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.triangleAlert, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Error selecting file: $e')),
              ],
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults(ScanResult result) {
    if (result.status != ScanStatus.completed) {
      return _buildNonCompletedResult(result);
    }

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
              const Text(
                'Scan Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                result.target,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
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
                            color: config.color,
                          ),
                        ),
                        Text(
                          'Detected by ${result.enginesDetected} of '
                          '${result.totalEngines} security engines',
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
                    widthFactor: result.totalEngines > 0 ? (result.enginesDetected / result.totalEngines) : 0,
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
          if (result.message.isNotEmpty && result.message != 'Scan completed successfully') ...[
            const SizedBox(height: 24),
            Text(
              result.message,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNonCompletedResult(ScanResult result) {
    IconData icon;
    Color color;
    String title;

    switch (result.status) {
      case ScanStatus.pending:
        icon = LucideIcons.hourglass;
        color = AppTheme.info;
        title = 'Scan Pending';
        break;
      case ScanStatus.notFound:
        icon = LucideIcons.searchX;
        color = AppTheme.textSecondary;
        title = 'Target Not Found';
        break;
      case ScanStatus.notConfigured:
        icon = LucideIcons.settings;
        color = AppTheme.warning;
        title = 'Scanner Not Configured';
        break;
      case ScanStatus.quotaExceeded:
        icon = LucideIcons.ban;
        color = AppTheme.error;
        title = 'Quota Exceeded';
        break;
      case ScanStatus.invalidTarget:
        icon = LucideIcons.triangleAlert;
        color = AppTheme.warning;
        title = 'Invalid Target';
        break;
      default:
        icon = LucideIcons.cloudOff;
        color = AppTheme.error;
        title = 'Scanner Unavailable';
    }

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
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                result.target,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    result.message,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Display ──────────────────────────────────────────────────────────

  Widget _buildError(String errorMsg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, color: AppTheme.error, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMsg,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Note ──────────────────────────────────────────────────────────────

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Note: This scanner uses VirusTotal API. '
        'Connect your API key in Settings to enable real scanning.',
        style: TextStyle(fontSize: 14, color: AppTheme.info),
      ),
    );
  }

  // ── Threat Config Helper ───────────────────────────────────────────────────

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

// ── Supporting Class ───────────────────────────────────────────────────────

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
