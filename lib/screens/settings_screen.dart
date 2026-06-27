import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildAPIKeysSection(provider),
                  const SizedBox(height: 24),
                  _buildMonitoringSection(provider),
                  const SizedBox(height: 24),
                  _buildAlertsSection(provider),
                  const SizedBox(height: 24),
                  _buildThemeSection(provider),
                  const SizedBox(height: 24),
                  _buildSaveButton(context, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── API Keys ───────────────────────────────────────────────────────────────

  Widget _buildAPIKeysSection(SettingsProvider provider) {
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
                    Icon(LucideIcons.key, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'API Keys',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Configure external service integrations',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildTextField(
                  'VirusTotal API Key',
                  provider.virusTotalApiKey,
                  provider.setVirusTotalApiKey,
                  'Enter your VirusTotal API key',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'GeoIP API Key',
                  provider.geoIPApiKey,
                  provider.setGeoIPApiKey,
                  'Enter your GeoIP API key',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'AbuseIPDB API Key',
                  provider.abuseIPDBApiKey,
                  provider.setAbuseIPDBApiKey,
                  'Enter your AbuseIPDB API key',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.borderPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderSecondary),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── Monitoring ─────────────────────────────────────────────────────────────

  Widget _buildMonitoringSection(SettingsProvider provider) {
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Configure background monitoring and scanning',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildToggleOption(
              'Background Monitoring',
              'Continuously monitor network traffic for threats',
              provider.backgroundMonitoring,
              provider.toggleBackgroundMonitoring,
            ),
          ),
        ],
      ),
    );
  }

  // ── Alerts ─────────────────────────────────────────────────────────────────

  Widget _buildAlertsSection(SettingsProvider provider) {
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
                      'Alerts',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Configure notification preferences',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildToggleOption(
                  'Email Alerts',
                  'Receive threat alerts via email',
                  provider.emailAlerts,
                  provider.toggleEmailAlerts,
                ),
                const SizedBox(height: 16),
                _buildToggleOption(
                  'Push Notifications',
                  'Receive real-time push notifications',
                  provider.pushAlerts,
                  provider.togglePushAlerts,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String description,
    bool value,
    VoidCallback onToggle,
  ) {
    return Container(
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
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppTheme.primary : AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Theme ──────────────────────────────────────────────────────────────────

  Widget _buildThemeSection(SettingsProvider provider) {
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                    !provider.darkMode,
                    () => provider.setDarkMode(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeOption(
                    'Dark',
                    LucideIcons.moon,
                    provider.darkMode,
                    () => provider.setDarkMode(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildSaveButton(BuildContext context, SettingsProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleSave(context, provider),
        icon: const Icon(LucideIcons.save, size: 20),
        label: const Text('Save Settings'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// Saves settings and shows a confirmation snackbar.
  /// When backend is ready, this will also persist to Supabase.
  void _handleSave(BuildContext context, SettingsProvider provider) {
    provider.saveSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.circleCheck, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Settings saved successfully.'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}
