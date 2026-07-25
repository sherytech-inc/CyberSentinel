import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/threat_intel_provider.dart';
import '../models/intel_model.dart';

class IPAnalysisScreen extends StatelessWidget {
  const IPAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreatIntelProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildSearchSection(context, provider),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 24),
                    _buildError(provider.errorMessage!),
                  ] else if (provider.intelResponse != null) ...[
                    const SizedBox(height: 24),
                    _buildResults(provider.intelResponse!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Search Section ─────────────────────────────────────────────────────────

  Widget _buildSearchSection(
      BuildContext context, ThreatIntelProvider provider) {
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
            'Threat Intelligence Lookup',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lookup an IP address across VirusTotal, AbuseIPDB, and GeoIP',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // ── IP Input ──
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter an IP address...',
              prefixIcon: const Icon(LucideIcons.globe, size: 20),
              filled: true,
              fillColor: AppTheme.borderPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderSecondary),
              ),
            ),
            onChanged: provider.setSearchQuery,
            onSubmitted: (_) => _handleSearch(context, provider),
          ),

          const SizedBox(height: 24),

          // ── Search Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () => _handleSearch(context, provider),
              icon: const Icon(LucideIcons.search, size: 24),
              label: Text(
                provider.isLoading ? 'Looking up...' : 'Lookup IP',
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
      ),
    );
  }

  void _handleSearch(BuildContext context, ThreatIntelProvider provider) {
    final hasIp = provider.searchQuery.trim().isNotEmpty;

    if (!hasIp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.triangleAlert, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Please enter an IP address before searching.'),
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

    provider.analyzeIP();
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults(IntelligenceResponse response) {
    if (response.status == IntelStatus.notConfigured) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: Border.all(color: AppTheme.borderPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: const [
            Icon(LucideIcons.settings, size: 64, color: AppTheme.warning),
            SizedBox(height: 24),
            Text(
              'Threat Intelligence Disabled',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Threat intelligence providers are not configured in the local CyberSentinel service. GeoIP may remain available independently.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildOverallScore(response),
        const SizedBox(height: 24),
        _buildProviderCard(
          title: 'VirusTotal',
          icon: LucideIcons.shield,
          status: response.virustotal.status,
          message: response.virustotal.message,
          child: response.virustotal.status == IntelProviderStatus.completed
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Malicious: ${response.virustotal.malicious} / ${response.virustotal.totalEngines}'),
                    Text('Suspicious: ${response.virustotal.suspicious}'),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 16),
        _buildProviderCard(
          title: 'AbuseIPDB',
          icon: LucideIcons.database,
          status: response.abuseipdb.status,
          message: response.abuseipdb.message,
          child: response.abuseipdb.status == IntelProviderStatus.completed
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Confidence Score: ${response.abuseipdb.abuseConfidenceScore}%'),
                    Text('Total Reports: ${response.abuseipdb.totalReports}'),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 16),
        _buildProviderCard(
          title: 'GeoIP',
          icon: LucideIcons.mapPin,
          status: response.geoip.status,
          message: response.geoip.message,
          child: response.geoip.status == IntelProviderStatus.completed
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Location: ${response.geoip.city}, ${response.geoip.country}'),
                    Text('ISP: ${response.geoip.isp} (${response.geoip.asn})'),
                    if (response.geoip.isProxy == true)
                      const Text('Is Proxy: Yes',
                          style: TextStyle(color: AppTheme.warning)),
                    if (response.geoip.isHosting == true)
                      const Text('Is Hosting: Yes',
                          style: TextStyle(color: AppTheme.info)),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildOverallScore(IntelligenceResponse response) {
    Color color = AppTheme.success;
    if (response.severity == 'critical' || response.severity == 'high')
      color = AppTheme.error;
    else if (response.severity == 'medium') color = AppTheme.warning;

    if (response.status != IntelStatus.completed &&
        response.status != IntelStatus.partial) {
      color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Risk Score',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                response.intelScore?.toString() ?? 'N/A',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Severity: ${response.severity?.toUpperCase() ?? 'UNKNOWN'}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${response.status.name.toUpperCase()}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String title,
    required IconData icon,
    required IntelProviderStatus status,
    required String? message,
    Widget? child,
  }) {
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case IntelProviderStatus.completed:
        statusIcon = LucideIcons.check;
        statusColor = AppTheme.success;
        break;
      case IntelProviderStatus.notConfigured:
        statusIcon = LucideIcons.settings;
        statusColor = AppTheme.textSecondary;
        break;
      case IntelProviderStatus.notFound:
        statusIcon = LucideIcons.searchX;
        statusColor = AppTheme.textSecondary;
        break;
      case IntelProviderStatus.quotaExceeded:
        statusIcon = LucideIcons.ban;
        statusColor = AppTheme.error;
        break;
      case IntelProviderStatus.unavailable:
        statusIcon = LucideIcons.cloudOff;
        statusColor = AppTheme.error;
        break;
    }

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
              Icon(icon, size: 24, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message != null &&
              message.isNotEmpty &&
              status != IntelProviderStatus.completed) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ]
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
          const Icon(LucideIcons.triangleAlert,
              color: AppTheme.error, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lookup Failed',
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
}
