import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/scan_result.dart';
import '../providers/virus_scanner_provider.dart';

enum ScannerType { url, hash, file }

class VirusScannerScreen extends StatefulWidget {
  const VirusScannerScreen({super.key});

  @override
  State<VirusScannerScreen> createState() => _VirusScannerScreenState();
}

class _VirusScannerScreenState extends State<VirusScannerScreen> {
  final _urlController = TextEditingController();
  final _hashController = TextEditingController();
  ScannerType _type = ScannerType.url;

  @override
  void dispose() {
    _urlController.dispose();
    _hashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VirusScannerProvider>(builder: (context, provider, _) {
      final result = _resultFor(provider);
      final loading = _loadingFor(provider);
      final error = _errorFor(provider);
      return LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            VirusScannerHeader(serviceLabel: _serviceLabel(result)),
            const SizedBox(height: AppTheme.spacing24),
            if (narrow)
              Column(children: [
                _workspace(provider),
                const SizedBox(height: AppTheme.spacing16),
                _resultPanel(provider, result, loading, error),
              ])
            else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 42, child: _workspace(provider)),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                    flex: 58,
                    child: _resultPanel(provider, result, loading, error)),
              ]),
            if (provider.recentScans.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing16),
              RecentScansPanel(
                results: provider.recentScans,
                onOpen: (scan) =>
                    setState(() => _type = switch (scan.scanType) {
                          'hash' => ScannerType.hash,
                          'file' => ScannerType.file,
                          _ => ScannerType.url,
                        }),
              ),
            ],
          ]),
        );
      });
    });
  }

  Widget _workspace(VirusScannerProvider provider) => _Panel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Scan workspace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spacing16),
          ScannerTypeSelector(
            selected: _type,
            onSelected: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: AppTheme.spacing24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: switch (_type) {
              ScannerType.url => UrlScanForm(
                  key: const ValueKey('url-form'),
                  controller: _urlController,
                  loading: provider.urlScanning,
                  error: provider.urlError,
                  onChanged: (value) {
                    provider.clearUrlError();
                    provider.setUrlInput(value);
                  },
                  onSubmit: provider.scanUrl,
                ),
              ScannerType.hash => HashScanForm(
                  key: const ValueKey('hash-form'),
                  controller: _hashController,
                  loading: provider.hashScanning,
                  error: provider.hashError,
                  hashType: provider.detectedHashType,
                  onChanged: (value) {
                    provider.clearHashError();
                    provider.setHashInput(value);
                  },
                  onSubmit: provider.scanHash,
                ),
              ScannerType.file => FileUploadPanel(
                  key: const ValueKey('file-form'),
                  filename: provider.fileInput,
                  fileSize: provider.selectedFileSize,
                  loading: provider.fileScanning,
                  error: provider.fileError,
                  onChoose: () => _chooseFile(provider),
                  onRemove: provider.removeSelectedFile,
                  onSubmit: provider.scanSelectedFile,
                ),
            },
          ),
          const SizedBox(height: AppTheme.spacing24),
          const Row(children: [
            Icon(LucideIcons.lockKeyhole,
                size: 14, color: AppTheme.textTertiary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Scans are processed securely through the local CyberSentinel service.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ),
          ]),
        ]),
      );

  Widget _resultPanel(VirusScannerProvider provider, ScanResult? result,
      bool loading, String? error) {
    final inlineValidation = error == 'Enter a valid HTTP or HTTPS URL.' ||
        error == 'Enter a valid MD5, SHA-1, or SHA-256 hash.';
    return _Panel(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: loading
            ? ScanLoadingState(key: const ValueKey('loading'), type: _type)
            : error != null && !inlineValidation
                ? ScanErrorState(
                    key: const ValueKey('error'),
                    message: error,
                    onRetry: () => _submit(provider),
                  )
                : result == null
                    ? const ScanEmptyState(key: ValueKey('empty'))
                    : ScanResultPanel(
                        key: ValueKey(
                            '${result.scanType}:${result.target}:${result.status.name}'),
                        result: result,
                        onRetry: result.status == ScanStatus.pending ||
                                result.status == ScanStatus.unavailable ||
                                result.status == ScanStatus.quotaExceeded
                            ? () => _submit(provider)
                            : null,
                      ),
      ),
    );
  }

  ScanResult? _resultFor(VirusScannerProvider p) => switch (_type) {
        ScannerType.url => p.urlResult,
        ScannerType.hash => p.hashResult,
        ScannerType.file => p.fileResult,
      };
  bool _loadingFor(VirusScannerProvider p) => switch (_type) {
        ScannerType.url => p.urlScanning,
        ScannerType.hash => p.hashScanning,
        ScannerType.file => p.fileScanning,
      };
  String? _errorFor(VirusScannerProvider p) => switch (_type) {
        ScannerType.url => p.urlError,
        ScannerType.hash => p.hashError,
        ScannerType.file => p.fileError,
      };
  Future<void> _submit(VirusScannerProvider p) => switch (_type) {
        ScannerType.url => p.scanUrl(),
        ScannerType.hash => p.scanHash(),
        ScannerType.file => p.scanSelectedFile(),
      };

  String _serviceLabel(ScanResult? result) {
    if (result?.status == ScanStatus.notConfigured) {
      return 'Not configured';
    }
    if (result?.status == ScanStatus.unavailable) {
      return 'Temporarily unavailable';
    }
    if (result?.providerContacted == true) {
      return 'VirusTotal connected';
    }
    return 'Limited service';
  }

  Future<void> _chooseFile(VirusScannerProvider provider) async {
    provider.clearFileError();
    try {
      final selection = await FilePicker.platform.pickFiles(withData: true);
      final file = selection?.files.firstOrNull;
      if (file?.bytes != null) {
        provider.selectFile(file!.name, file.bytes!);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The selected file could not be read.'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }
}

class VirusScannerHeader extends StatelessWidget {
  const VirusScannerHeader({super.key, required this.serviceLabel});
  final String serviceLabel;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Virus & Malware Scanner',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text(
                'Inspect URLs, file hashes and uploaded files for known threats.',
                style: TextStyle(color: AppTheme.textSecondary)),
          ]),
          _StatusPill(label: serviceLabel),
        ],
      );
}

class ScannerTypeSelector extends StatelessWidget {
  const ScannerTypeSelector(
      {super.key, required this.selected, required this.onSelected});
  final ScannerType selected;
  final ValueChanged<ScannerType> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.bgPrimary,
          border: Border.all(color: AppTheme.borderPrimary),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: ScannerType.values.map((type) {
            final active = selected == type;
            final (icon, title) = switch (type) {
              ScannerType.url => (LucideIcons.link2, 'URL'),
              ScannerType.hash => (LucideIcons.hash, 'Hash'),
              ScannerType.file => (LucideIcons.fileUp, 'File'),
            };
            return Expanded(
              child: Semantics(
                selected: active,
                button: true,
                child: InkWell(
                  key: ValueKey('scanner-tab-${type.name}'),
                  onTap: () => onSelected(type),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primary.withValues(alpha: .12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon,
                              size: 17,
                              color: active
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary),
                          const SizedBox(width: 7),
                          Flexible(
                              child: Text(title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary))),
                        ]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class UrlScanForm extends StatelessWidget {
  const UrlScanForm(
      {super.key,
      required this.controller,
      required this.loading,
      required this.error,
      required this.onChanged,
      required this.onSubmit});
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _FieldLabel('URL to inspect'),
        TextField(
          key: const ValueKey('url-input'),
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (_) {
            if (!loading) onSubmit();
          },
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
              hintText: 'https://example.com',
              prefixIcon: Icon(LucideIcons.link2, size: 19)),
        ),
        const SizedBox(height: 8),
        _InlineHelp(
            text: error ?? 'Only HTTP and HTTPS URLs are supported.',
            isError: error != null),
        const SizedBox(height: 20),
        _PrimaryScanButton(
            label: 'Scan URL', loading: loading, onPressed: onSubmit),
      ]);
}

class HashScanForm extends StatelessWidget {
  const HashScanForm(
      {super.key,
      required this.controller,
      required this.loading,
      required this.error,
      required this.hashType,
      required this.onChanged,
      required this.onSubmit});
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final String? hashType;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _FieldLabel('File hash'),
        TextField(
          key: const ValueKey('hash-input'),
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (_) {
            if (!loading) onSubmit();
          },
          decoration: const InputDecoration(
              hintText: 'Paste a file hash',
              prefixIcon: Icon(LucideIcons.hash, size: 19)),
        ),
        const SizedBox(height: 8),
        _InlineHelp(
            text: error ??
                (hashType == null
                    ? 'MD5 · SHA-1 · SHA-256'
                    : 'Detected: $hashType'),
            isError: error != null),
        const SizedBox(height: 20),
        _PrimaryScanButton(
            label: 'Look Up Hash', loading: loading, onPressed: onSubmit),
      ]);
}

class FileUploadPanel extends StatelessWidget {
  const FileUploadPanel(
      {super.key,
      required this.filename,
      required this.fileSize,
      required this.loading,
      required this.error,
      required this.onChoose,
      required this.onRemove,
      required this.onSubmit});
  final String filename;
  final int fileSize;
  final bool loading;
  final String? error;
  final VoidCallback onChoose;
  final VoidCallback onRemove;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (filename.isEmpty)
          InkWell(
            key: const ValueKey('file-drop-zone'),
            onTap: onChoose,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              decoration: BoxDecoration(
                  color: AppTheme.bgPrimary,
                  border: Border.all(color: AppTheme.borderSecondary),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              child: const Column(children: [
                Icon(LucideIcons.cloudUpload,
                    color: AppTheme.primary, size: 34),
                SizedBox(height: 12),
                Text('Drop a file here',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 5),
                Text('or choose a file from your device',
                    style: TextStyle(color: AppTheme.textSecondary)),
                SizedBox(height: 10),
                Text('Maximum supported size: 10 MB',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
              ]),
            ),
          )
        else
          Container(
            key: const ValueKey('selected-file-card'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppTheme.bgPrimary,
                border: Border.all(color: AppTheme.borderPrimary),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            child: Row(children: [
              const Icon(LucideIcons.file, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(filename,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('${_formatBytes(fileSize)} · ${_extension(filename)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ])),
              Tooltip(
                  message: 'Change file',
                  child: IconButton(
                      onPressed: loading ? null : onChoose,
                      icon: const Icon(LucideIcons.refreshCw, size: 18))),
              Tooltip(
                  message: 'Remove file',
                  child: IconButton(
                      onPressed: loading ? null : onRemove,
                      icon: const Icon(LucideIcons.x, size: 18))),
            ]),
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          _InlineHelp(text: error!, isError: true)
        ],
        const SizedBox(height: 20),
        _PrimaryScanButton(
            label: filename.isEmpty ? 'Choose File' : 'Scan File',
            loading: loading,
            onPressed: filename.isEmpty ? () async => onChoose() : onSubmit),
      ]);

  static String _extension(String name) {
    final index = name.lastIndexOf('.');
    return index < 0 ? 'Unknown type' : name.substring(index + 1).toUpperCase();
  }

  static String _formatBytes(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1048576
          ? '${(bytes / 1024).toStringAsFixed(1)} KB'
          : '${(bytes / 1048576).toStringAsFixed(1)} MB';
}

class ScanEmptyState extends StatelessWidget {
  const ScanEmptyState({super.key});
  @override
  Widget build(BuildContext context) => const _CenteredState(
        icon: Icons.security_outlined,
        title: 'No scan result yet',
        message:
            'Submit a URL, file hash, or file to view its security analysis.',
        footer: Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [
              _CapabilityHint('Engine verdicts'),
              _CapabilityHint('Detection counts'),
              _CapabilityHint('Scan metadata'),
            ]),
      );
}

class ScanLoadingState extends StatelessWidget {
  const ScanLoadingState({super.key, required this.type});
  final ScannerType type;
  @override
  Widget build(BuildContext context) => _CenteredState(
        icon: LucideIcons.scanSearch,
        title:
            'Analyzing ${type == ScannerType.url ? 'URL' : type == ScannerType.hash ? 'hash' : 'file'}',
        message: type == ScannerType.file
            ? 'Uploading and submitting to threat-intelligence providers…'
            : 'Submitting to threat-intelligence providers…',
        footer: const SizedBox(
            width: 180, child: LinearProgressIndicator(minHeight: 3)),
      );
}

class ScanErrorState extends StatelessWidget {
  const ScanErrorState(
      {super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _CenteredState(
        icon: LucideIcons.cloudOff,
        iconColor: AppTheme.warning,
        title: 'Scan temporarily unavailable',
        message: message,
        footer: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Try Again')),
      );
}

class ScanResultPanel extends StatelessWidget {
  const ScanResultPanel({super.key, required this.result, this.onRetry});
  final ScanResult result;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (result.status != ScanStatus.completed) return _nonCompleted();
    final malicious = result.verdict.toLowerCase() == 'malicious';
    final suspicious = result.verdict.toLowerCase() == 'suspicious';
    final color = malicious
        ? AppTheme.error
        : suspicious
            ? AppTheme.warning
            : AppTheme.success;
    final icon = malicious
        ? LucideIcons.shieldAlert
        : suspicious
            ? LucideIcons.triangleAlert
            : LucideIcons.shieldCheck;
    final verdict = malicious
        ? 'Malicious'
        : suspicious
            ? 'Suspicious'
            : 'Clean';
    return Column(
        key: const ValueKey('completed-result'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScanVerdictHeader(
              icon: icon,
              color: color,
              verdict: verdict,
              subtitle: 'Analysis complete'),
          const SizedBox(height: 20),
          DetectionStatsGrid(result: result),
          const SizedBox(height: 20),
          ScanMetadataPanel(result: result),
          const SizedBox(height: 20),
          _InterpretationPanel(result: result),
        ]);
  }

  Widget _nonCompleted() {
    final (icon, color, title, text) = switch (result.status) {
      ScanStatus.pending => (
          LucideIcons.hourglass,
          AppTheme.info,
          'Analysis pending',
          'VirusTotal accepted the submission and is still processing it.'
        ),
      ScanStatus.notFound => (
          LucideIcons.searchX,
          AppTheme.textSecondary,
          'No existing report found',
          'VirusTotal has no previous analysis for this hash.'
        ),
      ScanStatus.notConfigured => (
          LucideIcons.settings,
          AppTheme.warning,
          'Scanner not configured',
          'VirusTotal scanning is not configured for this local service.'
        ),
      ScanStatus.quotaExceeded => (
          LucideIcons.timerOff,
          AppTheme.warning,
          'Scan rate limited',
          'The threat-intelligence provider is busy. Try again shortly.'
        ),
      ScanStatus.fileTooLarge => (
          LucideIcons.fileWarning,
          AppTheme.warning,
          'File too large',
          result.message
        ),
      ScanStatus.invalidTarget => (
          LucideIcons.triangleAlert,
          AppTheme.warning,
          'Invalid target',
          result.message
        ),
      ScanStatus.failed => (
          LucideIcons.circleX,
          AppTheme.warning,
          'Scan failed',
          result.message
        ),
      _ => (
          LucideIcons.cloudOff,
          AppTheme.warning,
          'Scan temporarily unavailable',
          'The threat-intelligence service could not be reached. Try again shortly.'
        ),
    };
    return _CenteredState(
      key: ValueKey('result-${result.status.name}'),
      icon: icon,
      iconColor: color,
      title: title,
      message: text,
      footer: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(result.status == ScanStatus.pending
                  ? 'Check again'
                  : 'Try Again')),
    );
  }
}

class ScanVerdictHeader extends StatelessWidget {
  const ScanVerdictHeader(
      {super.key,
      required this.icon,
      required this.color,
      required this.verdict,
      required this.subtitle});
  final IconData icon;
  final Color color;
  final String verdict;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            border: Border.all(color: color.withValues(alpha: .25)),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Row(children: [
          Icon(icon, color: color, size: 38),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(verdict,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(subtitle,
                style: const TextStyle(color: AppTheme.textSecondary))
          ])
        ]),
      );
}

class DetectionStatsGrid extends StatelessWidget {
  const DetectionStatsGrid({super.key, required this.result});
  final ScanResult result;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Malicious', result.malicious, AppTheme.error),
      ('Suspicious', result.suspicious, AppTheme.warning),
      ('Harmless', result.harmless, AppTheme.success),
      ('Undetected', result.undetected, AppTheme.textSecondary)
    ];
    return LayoutBuilder(builder: (context, c) {
      final width = math.max(100.0, (c.maxWidth - 10) / 2);
      return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => SizedBox(
                  width: width,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppTheme.bgPrimary,
                          border: Border.all(color: AppTheme.borderPrimary),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.$2}',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: item.$3)),
                            Text(item.$1,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary))
                          ]))))
              .toList());
    });
  }
}

class ScanMetadataPanel extends StatelessWidget {
  const ScanMetadataPanel({super.key, required this.result});
  final ScanResult result;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Scan metadata',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _MetadataRow(
            label: result.scanType == 'file'
                ? 'Filename'
                : result.scanType == 'hash'
                    ? 'File hash'
                    : 'Normalized URL',
            value: result.target,
            copyable: true),
        if (result.scanType == 'hash')
          _MetadataRow(label: 'Hash type', value: _hashType(result.target)),
        if (result.analysisId != null)
          _MetadataRow(label: 'Analysis ID', value: result.analysisId!),
        _MetadataRow(label: 'Provider', value: result.provider),
        if (result.scannedAt != null)
          _MetadataRow(label: 'Scanned', value: _formatDate(result.scannedAt!)),
      ]);
  static String _hashType(String value) => value.length == 32
      ? 'MD5'
      : value.length == 40
          ? 'SHA-1'
          : 'SHA-256';
  static String _formatDate(DateTime value) =>
      value.toLocal().toString().split('.').first;
}

class RecentScansPanel extends StatelessWidget {
  const RecentScansPanel(
      {super.key, required this.results, required this.onOpen});
  final List<ScanResult> results;
  final ValueChanged<ScanResult> onOpen;
  @override
  Widget build(BuildContext context) => _Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Recent scans',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...results.take(8).map((result) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
                result.scanType == 'url'
                    ? LucideIcons.link2
                    : result.scanType == 'hash'
                        ? LucideIcons.hash
                        : LucideIcons.file,
                size: 18,
                color: AppTheme.textSecondary),
            title: Text(result.target,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                result.status == ScanStatus.completed
                    ? result.verdict
                    : result.status.name,
                style: const TextStyle(color: AppTheme.textSecondary)),
            trailing: Tooltip(
                message: 'Open result',
                child: IconButton(
                    onPressed: () => onOpen(result),
                    icon: const Icon(LucideIcons.arrowUpRight, size: 17))))),
      ]));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: Border.all(color: AppTheme.borderPrimary),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: child);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = label == 'VirusTotal connected'
        ? AppTheme.success
        : label == 'Temporarily unavailable'
            ? AppTheme.error
            : AppTheme.warning;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            border: Border.all(color: color.withValues(alpha: .3)),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.circle, size: 8, color: color),
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))
        ]));
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)));
}

class _InlineHelp extends StatelessWidget {
  const _InlineHelp({required this.text, required this.isError});
  final String text;
  final bool isError;
  @override
  Widget build(BuildContext context) => Text(text,
      key: ValueKey(isError ? 'inline-error' : 'field-help'),
      style: TextStyle(
          fontSize: 12,
          color: isError ? AppTheme.error : AppTheme.textTertiary));
}

class _PrimaryScanButton extends StatelessWidget {
  const _PrimaryScanButton(
      {required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final Future<void> Function() onPressed;
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 17, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(LucideIcons.scanSearch, size: 18),
      label: Text(loading ? 'Scanning…' : label),
      style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14)));
}

class _CenteredState extends StatelessWidget {
  const _CenteredState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.iconColor = AppTheme.primary,
      this.footer});
  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 370),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .08),
                shape: BoxShape.circle),
            child: Icon(icon, size: 38, color: iconColor)),
        const SizedBox(height: 18),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, height: 1.5))),
        if (footer != null) ...[const SizedBox(height: 22), footer!],
      ])));
}

class _CapabilityHint extends StatelessWidget {
  const _CapabilityHint(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.check, size: 13, color: AppTheme.primary),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
      ]);
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow(
      {required this.label, required this.value, this.copyable = false});
  final String label;
  final String value;
  final bool copyable;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 105,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary))),
        Expanded(
            child: Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))),
        if (copyable)
          Tooltip(
              message: 'Copy',
              child: InkWell(
                  onTap: () => Clipboard.setData(ClipboardData(text: value)),
                  child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(LucideIcons.copy,
                          size: 14, color: AppTheme.textSecondary)))),
      ]));
}

class _InterpretationPanel extends StatelessWidget {
  const _InterpretationPanel({required this.result});
  final ScanResult result;
  @override
  Widget build(BuildContext context) {
    final malicious = result.malicious > 0;
    final suspicious = result.suspicious > 0;
    final text = malicious
        ? '${result.malicious} engine${result.malicious == 1 ? '' : 's'} marked this target as malicious. Avoid opening or sharing it until it has been investigated.'
        : suspicious
            ? '${result.suspicious} engine${result.suspicious == 1 ? '' : 's'} marked this target as suspicious. Review the target before trusting it.'
            : 'No participating engine marked this target as malicious or suspicious at the time of this scan.';
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.bgPrimary,
            border: Border.all(color: AppTheme.borderPrimary),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('What this means',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.45))
        ]));
  }
}
