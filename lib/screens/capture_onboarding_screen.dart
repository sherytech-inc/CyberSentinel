import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/capture_capability_provider.dart';
import '../models/capture_capability.dart';

class CaptureOnboardingScreen extends StatefulWidget {
  final VoidCallback onReady;
  const CaptureOnboardingScreen({super.key, required this.onReady});

  @override
  State<CaptureOnboardingScreen> createState() =>
      _CaptureOnboardingScreenState();
}

class _CaptureOnboardingScreenState extends State<CaptureOnboardingScreen> {
  String? _selectedInterface;

  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureCapabilityProvider>(
      builder: (context, provider, _) {
        final result = provider.capabilityResult;
        if (result == null || provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Network Capture Setup',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'CyberSentinel requires specific dependencies and permissions to capture live network traffic safely.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacing32),
              _buildDependencySection(result),
              const SizedBox(height: AppTheme.spacing24),
              if (result.dumpcapFound)
                _buildPermissionSection(context, provider, result),
              const SizedBox(height: AppTheme.spacing24),
              if (result.interfaces.isNotEmpty)
                _buildInterfaceSelection(result),
              const SizedBox(height: AppTheme.spacing32),
              _buildActionSection(context, provider, result),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDependencySection(CaptureCapabilityResult result) {
    return _buildCard(
      title: '1. Capture Dependencies',
      icon: LucideIcons.box,
      child: Column(
        children: [
          _buildStatusRow(
            'TShark',
            result.tsharkFound,
            subtitle: result.tsharkVersion ?? 'Not found',
          ),
          const Divider(height: AppTheme.spacing24),
          _buildStatusRow(
            'Dumpcap (Wireshark)',
            result.dumpcapFound,
            subtitle: result.dumpcapVersion ?? 'Not found',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(BuildContext context,
      CaptureCapabilityProvider provider, CaptureCapabilityResult result) {
    final granted = result.permissionState == CapturePermissionState.granted;
    final needsRemediation =
        result.requiresUserAction && result.remediationCode != null;

    return _buildCard(
      title: '2. System Permissions',
      icon: LucideIcons.shieldAlert,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(
            'Capture Permissions',
            granted,
            subtitle: granted ? 'Granted' : 'Required',
          ),
          if (needsRemediation) ...[
            const SizedBox(height: AppTheme.spacing16),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderSecondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      result.remediationTitle ??
                          'Packet Capture Permission Required',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                      result.remediationMessage ??
                          'CyberSentinel requires the official Wireshark ChmodBPF helper to capture network traffic without running the application as an administrator.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppTheme.spacing16),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Text(
                      'brew install --cask wireshark-chmodbpf',
                      style: TextStyle(
                          fontFamily: 'monospace', color: Colors.greenAccent),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text('A Mac restart is required after installation.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.warning)),
                  const SizedBox(height: AppTheme.spacing16),
                  Wrap(
                    spacing: AppTheme.spacing8,
                    runSpacing: AppTheme.spacing8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(
                              text: 'brew install --cask wireshark-chmodbpf'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Command copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Installation Command'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(
                            'https://www.wireshark.org/docs/wsug_html_chunked/ChBuildInstallOSXInstall.html')),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text(
                            'Open Official Installation Instructions'),
                      ),
                      OutlinedButton.icon(
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.refreshCapabilities(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check Again'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInterfaceSelection(CaptureCapabilityResult result) {
    if (_selectedInterface == null && result.recommendedInterface != null) {
      _selectedInterface = result.recommendedInterface;
    }

    return _buildCard(
      title: '3. Select Interface',
      icon: LucideIcons.network,
      child: DropdownButtonFormField<String>(
        value: _selectedInterface,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.bgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(color: AppTheme.borderSecondary),
          ),
        ),
        items: result.interfaces.map((iface) {
          return DropdownMenuItem(
            value: iface.id,
            child: Text('${iface.displayName} (${iface.id})'),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedInterface = val;
          });
        },
      ),
    );
  }

  Widget _buildActionSection(BuildContext context,
      CaptureCapabilityProvider provider, CaptureCapabilityResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: provider.consentGiven,
          onChanged: (val) => provider.setConsentGiven(val ?? false),
          title: const Text(
              'I consent to capturing local network traffic for analysis.'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppTheme.spacing16),
        if (provider.error != null) ...[
          Text(provider.error!, style: TextStyle(color: AppTheme.error)),
          const SizedBox(height: AppTheme.spacing16),
        ],
        Row(
          children: [
            ElevatedButton(
              onPressed: (!provider.consentGiven ||
                      _selectedInterface == null ||
                      provider.isLoading)
                  ? null
                  : () async {
                      final success =
                          await provider.runProbe(_selectedInterface!);
                      if (success) {
                        widget.onReady();
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Run Test Probe'),
            ),
            const SizedBox(width: AppTheme.spacing16),
            TextButton(
              onPressed: provider.isLoading
                  ? null
                  : () => provider.refreshCapabilities(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: AppTheme.spacing12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOk, {String? subtitle}) {
    return Row(
      children: [
        Icon(
          isOk ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: isOk ? AppTheme.success : AppTheme.error,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacing12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            if (subtitle != null)
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}
