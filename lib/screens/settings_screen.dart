import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/integrations_provider.dart';
import '../models/integration_status.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IntegrationsProvider>().fetchIntegrations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildMonitoringSection(context),
              const SizedBox(height: 24),
              _buildIntegrationsSection(context),
              const SizedBox(height: 24),
              _buildAlertsSection(),
              const SizedBox(height: 24),

              _buildThemeSection(context),
              const SizedBox(height: 24),
              _buildSaveButton(context),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ── Monitoring ─────────────────────────────────────────────────────────────

  Widget _buildMonitoringSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border.all(color: AppTheme.borderPrimary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderPrimary)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(LucideIcons.globe, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Monitoring',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Configure automatic data refresh intervals',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Data Refresh Interval',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'How often to fetch new threat data',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<RefreshInterval>(
                        value: provider.refreshInterval,
                        underline: const SizedBox(),
                        dropdownColor: AppTheme.bgSecondary,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        onChanged: (RefreshInterval? newValue) {
                          if (newValue != null) {
                            provider.setRefreshInterval(newValue);
                          }
                        },
                        items: RefreshInterval.values.map((RefreshInterval interval) {
                          return DropdownMenuItem<RefreshInterval>(
                            value: interval,
                            child: Text(interval.label),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Integrations ───────────────────────────────────────────────────────────

  Widget _buildIntegrationsSection(BuildContext context) {
    return Consumer<IntegrationsProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border.all(color: AppTheme.borderPrimary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderPrimary)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(LucideIcons.plug, color: AppTheme.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Integrations',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Third-party security intelligence providers (Backend Only)',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => provider.fetchIntegrations(),
                        tooltip: 'Refresh Status',
                      ),
                  ],
                ),
              ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: AppTheme.error),
                  ),
                )
              else if (provider.integrations != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildIntegrationCard(
                        context,
                        provider,
                        'VirusTotal',
                        'virustotal',
                        provider.integrations!.virustotal,
                      ),
                      const SizedBox(height: 16),
                      _buildIntegrationCard(
                        context,
                        provider,
                        'AbuseIPDB',
                        'abuseipdb',
                        provider.integrations!.abuseipdb,
                      ),
                      const SizedBox(height: 16),
                      _buildIntegrationCard(
                        context,
                        provider,
                        'Groq (LLM)',
                        'groq',
                        provider.integrations!.groq,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntegrationCard(
    BuildContext context,
    IntegrationsProvider provider,
    String title,
    String providerId,
    IntegrationStatus status,
  ) {
    final isTesting = provider.isTesting(providerId);
    
    Color statusColor;
    IconData statusIcon;
    switch (status.state) {
      case 'reachable':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'not_configured':
        statusColor = AppTheme.textTertiary;
        statusIcon = LucideIcons.slash;
        break;
      case 'not_tested':
        statusColor = AppTheme.warning;
        statusIcon = Icons.help_outline;
        break;
      default:
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.borderPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.state.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: (isTesting || !status.configured) ? null : () => provider.testConnection(providerId),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(
                    color: (isTesting || !status.configured) 
                        ? AppTheme.borderSecondary 
                        : AppTheme.primary,
                  ),
                ),
                child: isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            status.message,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (status.maskedHint != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.key, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Key: ${status.maskedHint}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Alerts ─────────────────────────────────────────────────────────────────

  Widget _buildAlertsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderPrimary)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(LucideIcons.bell, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Configure email and push alerts',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.borderPrimary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.info, color: AppTheme.textSecondary, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email and push notifications are not available in this build.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ── Theme ──────────────────────────────────────────────────────────────────

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border.all(color: AppTheme.borderPrimary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderPrimary)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(LucideIcons.moon, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Appearance',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Customize the application theme',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildThemeOption(
                        'Light',
                        LucideIcons.sun,
                        provider.themeMode == ThemeMode.light,
                        () => provider.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildThemeOption(
                        'Dark',
                        LucideIcons.moon,
                        provider.themeMode == ThemeMode.dark || provider.themeMode == ThemeMode.system,
                        () => provider.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.borderPrimary,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderSecondary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save Button ────────────────────────────────────────────────────────────

  Widget _buildSaveButton(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleSave(context, provider),
            icon: const Icon(LucideIcons.save, size: 20),
            label: const Text('Save Local Preferences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave(BuildContext context, SettingsProvider provider) async {
    final success = await provider.saveSettings();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.info, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  kIsWeb
                      ? 'Preferences saved in this browser.'
                      : 'Preferences saved on this device.',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.textSecondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.triangleAlert, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to save preferences locally.')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }
}
