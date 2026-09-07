import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/integration_status.dart';
import '../providers/integrations_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Mirrors the `version:` field in pubspec.yaml. There is no package_info
  /// dependency, so this is the only way to surface it — keep the two in step.
  static const String _appVersion = '1.0.0';

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
              _buildMonitoringSection(),
              const SizedBox(height: CsSpacing.xl),
              _buildIntegrationsSection(),
              const SizedBox(height: CsSpacing.xl),
              _buildNotificationsSection(),
              const SizedBox(height: CsSpacing.xl),
              _buildThemeSection(),
              const SizedBox(height: CsSpacing.xl),
              _buildAboutSection(),
              const SizedBox(height: CsSpacing.xl),
              _buildSaveButton(context),
              const SizedBox(height: CsSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Monitoring ─────────────────────────────────────────────────────────────

  Widget _buildMonitoringSection() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final colors = CsColors.of(context);
        final text = CsTypography.of(context);

        return AppCard(
          icon: LucideIcons.globe,
          title: 'Monitoring',
          subtitle: 'Configure automatic data refresh intervals',
          child: Container(
            padding: const EdgeInsets.all(CsSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceHover,
              borderRadius: CsRadius.mediumBorder,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Refresh Interval',
                        style: text.title.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: CsSpacing.xs),
                      Text(
                        'How often to fetch new threat data',
                        style: text.bodySmall
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CsSpacing.md),
                DropdownButton<RefreshInterval>(
                  value: provider.refreshInterval,
                  underline: const SizedBox(),
                  dropdownColor: colors.surfaceElevated,
                  borderRadius: CsRadius.mediumBorder,
                  iconEnabledColor: colors.textSecondary,
                  style: text.body.copyWith(color: colors.textPrimary),
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
        );
      },
    );
  }

  // ── Integrations ───────────────────────────────────────────────────────────

  Widget _buildIntegrationsSection() {
    return Consumer<IntegrationsProvider>(
      builder: (context, provider, _) {
        final colors = CsColors.of(context);

        return AppCard(
          icon: LucideIcons.plug,
          title: 'Integrations',
          subtitle:
              'Third-party security intelligence providers (Backend Only)',
          trailing: provider.isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : IconButton(
                  icon: Icon(LucideIcons.refreshCw,
                      size: 18, color: colors.textSecondary),
                  onPressed: provider.fetchIntegrations,
                  tooltip: 'Refresh Status',
                ),
          child: _buildIntegrationsBody(context, provider),
        );
      },
    );
  }

  Widget _buildIntegrationsBody(
    BuildContext context,
    IntegrationsProvider provider,
  ) {
    if (provider.error != null) {
      return ErrorState(
        compact: true,
        message: provider.error,
        onRetry: provider.fetchIntegrations,
      );
    }

    final integrations = provider.integrations;
    if (integrations == null) {
      return provider.isLoading
          ? const LoadingState.inline(message: 'Checking integrations')
          : const EmptyState(
              compact: true,
              title: 'No integration status available',
              description: 'Use refresh to query the configured providers.',
            );
    }

    return Column(
      children: [
        _buildIntegrationCard(
          context,
          provider,
          'VirusTotal',
          'virustotal',
          integrations.virustotal,
        ),
        const SizedBox(height: CsSpacing.lg),
        _buildIntegrationCard(
          context,
          provider,
          'AbuseIPDB',
          'abuseipdb',
          integrations.abuseipdb,
        ),
        const SizedBox(height: CsSpacing.lg),
        _buildIntegrationCard(
          context,
          provider,
          'Groq (LLM)',
          'groq',
          integrations.groq,
        ),
      ],
    );
  }

  Widget _buildIntegrationCard(
    BuildContext context,
    IntegrationsProvider provider,
    String title,
    String providerId,
    IntegrationStatus status,
  ) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final isTesting = provider.isTesting(providerId);
    final unavailable = isTesting || !status.configured;

    return Container(
      padding: const EdgeInsets.all(CsSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceHover,
        borderRadius: CsRadius.mediumBorder,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Wrap(
                  spacing: CsSpacing.md,
                  runSpacing: CsSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: text.title.copyWith(color: colors.textPrimary),
                    ),
                    StatusBadge.fromString(
                      status.state,
                      label: _humanise(status.state),
                      size: CsBadgeSize.sm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CsSpacing.md),
              OutlinedButton(
                onPressed: unavailable
                    ? null
                    : () => provider.testConnection(providerId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  disabledForegroundColor: colors.textDisabled,
                  side: BorderSide(
                    color: unavailable ? colors.border : colors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CsSpacing.lg,
                    vertical: CsSpacing.sm,
                  ),
                  minimumSize: const Size(0, CsHitTarget.minimum),
                  textStyle: text.labelMedium,
                  shape: const RoundedRectangleBorder(
                    borderRadius: CsRadius.mediumBorder,
                  ),
                ),
                child: isTesting
                    ? const LoadingState.button()
                    : const Text('Test Connection'),
              ),
            ],
          ),
          const SizedBox(height: CsSpacing.md),
          Text(
            status.message,
            style: text.bodySmall.copyWith(color: colors.textSecondary),
          ),
          if (status.maskedHint != null) ...[
            const SizedBox(height: CsSpacing.sm),
            Row(
              children: [
                Icon(LucideIcons.key, size: 13, color: colors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Key: ${status.maskedHint}',
                    style: text.caption.copyWith(
                      color: colors.textTertiary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// `not_configured` → `Not configured`. The badge takes its colour and icon
  /// from the semantic tokens; this only supplies the wording, so the state is
  /// never conveyed by colour alone.
  static String _humanise(String state) {
    return state
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Widget _buildNotificationsSection() {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return AppCard(
      icon: LucideIcons.bell,
      title: 'Notifications',
      subtitle: 'Configure email and push alerts',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(CsSpacing.lg),
        decoration: BoxDecoration(
          color: colors.infoBackground,
          borderRadius: CsRadius.mediumBorder,
          border: Border.all(color: CsColors.hairline(colors.info)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.info, color: colors.info, size: 16),
            const SizedBox(width: CsSpacing.md),
            Expanded(
              child: Text(
                'Email and push notifications are not available in this '
                'build.',
                style: text.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Appearance ─────────────────────────────────────────────────────────────

  Widget _buildThemeSection() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return AppCard(
          icon: LucideIcons.moon,
          title: 'Appearance',
          subtitle: 'Customize the application theme',
          child: Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  context,
                  'Light',
                  LucideIcons.sun,
                  provider.themeMode == ThemeMode.light,
                  () => provider.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: CsSpacing.md),
              Expanded(
                child: _buildThemeOption(
                  context,
                  'Dark',
                  LucideIcons.moon,
                  provider.themeMode == ThemeMode.dark ||
                      provider.themeMode == ThemeMode.system,
                  () => provider.setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label theme',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(CsSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? CsColors.tint(colors.primary)
                : colors.surfaceHover,
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: CsRadius.mediumBorder,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: CsSpacing.sm),
              Text(
                label,
                style: text.label.copyWith(
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
              // Selection is marked with a glyph as well as colour.
              if (isSelected) ...[
                const SizedBox(width: CsSpacing.sm),
                Icon(LucideIcons.circleCheck, size: 15, color: colors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── About ──────────────────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return AppCard(
      icon: LucideIcons.info,
      title: 'About',
      subtitle: 'Product and build information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CyberSentinelLockup(size: 30),
          const SizedBox(height: CsSpacing.md),
          Text(
            'CyberSentinel captures local network traffic, correlates it '
            'with threat intelligence, and surfaces suspicious activity for '
            'review.',
            style: text.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: CsSpacing.lg),
          Divider(color: colors.border, height: 1, thickness: 1),
          const SizedBox(height: CsSpacing.md),
          _buildFactRow(context, 'Version', _appVersion),
          _buildFactRow(
            context,
            'Platform',
            kIsWeb ? 'Web' : 'Desktop (${defaultTargetPlatform.name})',
          ),
          _buildFactRow(
            context,
            'Preferences',
            kIsWeb ? 'Stored in this browser' : 'Stored on this device',
          ),
        ],
      ),
    );
  }

  Widget _buildFactRow(BuildContext context, String label, String value) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: text.bodySmall.copyWith(color: colors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Widget _buildSaveButton(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final colors = CsColors.of(context);
        final text = CsTypography.of(context);

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleSave(context, provider),
            icon: const Icon(LucideIcons.save, size: 18),
            label: const Text('Save Local Preferences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.primaryForeground,
              disabledBackgroundColor: colors.surfaceHover,
              disabledForegroundColor: colors.textDisabled,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: CsSpacing.md),
              textStyle: text.label,
              shape: const RoundedRectangleBorder(
                borderRadius: CsRadius.mediumBorder,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave(
      BuildContext context, SettingsProvider provider) async {
    final success = await provider.saveSettings();

    if (!context.mounted) return;

    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.circleCheck, color: colors.success, size: 18),
              const SizedBox(width: CsSpacing.sm),
              Expanded(
                child: Text(
                  kIsWeb
                      ? 'Preferences saved in this browser.'
                      : 'Preferences saved on this device.',
                  style: text.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: colors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: CsRadius.mediumBorder,
            side: BorderSide(color: colors.border),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.triangleAlert, color: colors.error, size: 18),
              const SizedBox(width: CsSpacing.sm),
              Expanded(
                child: Text(
                  'Failed to save preferences locally.',
                  style: text.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: colors.errorBackground,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: CsRadius.mediumBorder,
            side: BorderSide(color: CsColors.hairline(colors.error)),
          ),
        ),
      );
    }
  }
}
