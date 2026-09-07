import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cs_colors.dart';

/// Alert/investigation severity. One vocabulary for the whole app.
enum Severity { low, medium, high, critical, unknown }

/// Packet and alert classification.
enum ThreatClassification { normal, suspicious, malicious, pending, unknown }

/// Lifecycle/availability status. Deliberately richer than a boolean so that
/// "recorded but not enforced" and "skipped" stay visually distinct from
/// "succeeded".
enum StatusKind {
  active,
  inactive,
  success,
  warning,
  critical,
  pending,
  partial,
  complete,
  failed,
  recordedOnly,
  skipped,
  unknown,
}

/// A fully resolved visual state: colour, wash, outline, human label and icon.
///
/// Colour is never the only carrier of meaning — [label] and [icon] accompany
/// it, so the state stays readable for colour-blind users.
@immutable
class SemanticState {
  const SemanticState({
    required this.foreground,
    required this.background,
    required this.border,
    required this.label,
    required this.icon,
    this.indeterminate = false,
  });

  final Color foreground;
  final Color background;
  final Color border;
  final String label;
  final IconData icon;

  /// True when this state carries no evidence about safety — absent, pending or
  /// skipped data. Callers must not render these as a healthy/safe result.
  final bool indeterminate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticState &&
          foreground == other.foreground &&
          background == other.background &&
          border == other.border &&
          label == other.label &&
          icon == other.icon &&
          indeterminate == other.indeterminate;

  @override
  int get hashCode =>
      Object.hash(foreground, background, border, label, icon, indeterminate);
}

/// Single source of truth mapping semantic states to colours, labels and icons.
///
/// Backend payloads still deliver severity and status as strings in several
/// vocabularies (`'CRITICAL'`, `'medium'`, `'MALICIOUS'`). The `parse` helpers
/// absorb that variety here, in the presentation layer, so no model or provider
/// has to change.
class CsSemantics {
  CsSemantics._();

  /// Score thresholds shared with the existing dashboard card: >=70 critical,
  /// >=40 medium, otherwise low. A null score is [Severity.unknown] and must
  /// never be rendered as a healthy zero.
  static Severity severityFromScore(num? score) {
    if (score == null) {
      return Severity.unknown;
    }
    if (score >= 70) {
      return Severity.critical;
    }
    if (score >= 40) {
      return Severity.medium;
    }
    return Severity.low;
  }

  static Severity parseSeverity(String? raw) {
    switch (_normalise(raw)) {
      case 'low':
      case 'info':
      case 'informational':
      case 'minor':
        return Severity.low;
      case 'medium':
      case 'med':
      case 'moderate':
      case 'warning':
        return Severity.medium;
      case 'high':
      case 'major':
      case 'severe':
        return Severity.high;
      case 'critical':
      case 'crit':
      case 'emergency':
        return Severity.critical;
      default:
        return Severity.unknown;
    }
  }

  static ThreatClassification parseClassification(String? raw) {
    switch (_normalise(raw)) {
      case 'normal':
      case 'benign':
      case 'clean':
      case 'safe':
        return ThreatClassification.normal;
      case 'suspicious':
      case 'suspect':
      case 'anomaly':
        return ThreatClassification.suspicious;
      case 'malicious':
      case 'attack':
      case 'threat':
        return ThreatClassification.malicious;
      case 'pending':
      case 'queued':
      case 'analyzing':
      case 'in_progress':
        return ThreatClassification.pending;
      default:
        return ThreatClassification.unknown;
    }
  }

  static StatusKind parseStatus(String? raw) {
    switch (_normalise(raw)) {
      case 'active':
      case 'running':
      case 'monitoring':
      case 'online':
      case 'connected':
        return StatusKind.active;
      case 'inactive':
      case 'stopped':
      case 'idle':
      case 'offline':
      case 'disconnected':
        return StatusKind.inactive;
      case 'success':
      case 'succeeded':
      case 'ok':
      case 'healthy':
      case 'reachable':
        return StatusKind.success;
      case 'warning':
      case 'degraded':
        return StatusKind.warning;
      case 'critical':
      case 'error':
        return StatusKind.critical;
      case 'pending':
      case 'queued':
      case 'waiting':
      case 'starting':
      case 'stopping':
      case 'not_tested':
      case 'untested':
        return StatusKind.pending;
      case 'partial':
      case 'incomplete':
        return StatusKind.partial;
      case 'complete':
      case 'completed':
      case 'finished':
      case 'done':
        return StatusKind.complete;
      case 'failed':
      case 'failure':
      case 'not_found':
      case 'timeout':
      case 'unreachable':
        return StatusKind.failed;
      case 'recorded_only':
      case 'recorded':
      case 'logged_only':
        return StatusKind.recordedOnly;
      case 'skipped':
      case 'private':
      case 'reserved':
      case 'not_configured':
      case 'unconfigured':
        return StatusKind.skipped;
      default:
        return StatusKind.unknown;
    }
  }

  static SemanticState severity(Severity value, CsColors colors) {
    switch (value) {
      case Severity.low:
        return _build(colors.severityNormal, colors.successBackground, 'Low',
            LucideIcons.shieldCheck);
      case Severity.medium:
        return _build(colors.severitySuspicious, colors.warningBackground,
            'Medium', LucideIcons.circleAlert);
      case Severity.high:
        return _build(colors.severityMalicious, colors.errorBackground, 'High',
            LucideIcons.triangleAlert);
      case Severity.critical:
        return _build(colors.severityMalicious, colors.errorBackground,
            'Critical', LucideIcons.octagonAlert);
      case Severity.unknown:
        return _unknown(colors);
    }
  }

  static SemanticState classification(
      ThreatClassification value, CsColors colors) {
    switch (value) {
      case ThreatClassification.normal:
        return _build(colors.severityNormal, colors.successBackground, 'Normal',
            LucideIcons.circleCheck);
      case ThreatClassification.suspicious:
        return _build(colors.severitySuspicious, colors.warningBackground,
            'Suspicious', LucideIcons.triangleAlert);
      case ThreatClassification.malicious:
        return _build(colors.severityMalicious, colors.errorBackground,
            'Malicious', LucideIcons.ban);
      case ThreatClassification.pending:
        return _build(colors.severityPending, colors.infoBackground, 'Pending',
            LucideIcons.clock,
            indeterminate: true);
      case ThreatClassification.unknown:
        return _unknown(colors);
    }
  }

  static SemanticState status(StatusKind value, CsColors colors) {
    switch (value) {
      case StatusKind.active:
        return _build(colors.success, colors.successBackground, 'Active',
            LucideIcons.activity);
      case StatusKind.inactive:
        return _build(colors.textTertiary, colors.surfaceHover, 'Inactive',
            LucideIcons.circlePause);
      case StatusKind.success:
        return _build(colors.success, colors.successBackground, 'Success',
            LucideIcons.circleCheck);
      case StatusKind.warning:
        return _build(colors.warning, colors.warningBackground, 'Warning',
            LucideIcons.triangleAlert);
      case StatusKind.critical:
        return _build(colors.error, colors.errorBackground, 'Critical',
            LucideIcons.octagonAlert);
      case StatusKind.pending:
        return _build(
          colors.info,
          colors.infoBackground,
          'Pending',
          LucideIcons.clock,
          indeterminate: true,
        );
      case StatusKind.partial:
        return _build(
          colors.warning,
          colors.warningBackground,
          'Partial',
          LucideIcons.circleSlash,
          indeterminate: true,
        );
      case StatusKind.complete:
        return _build(colors.success, colors.successBackground, 'Complete',
            LucideIcons.circleCheck);
      case StatusKind.failed:
        return _build(colors.error, colors.errorBackground, 'Failed',
            LucideIcons.circleX);
      case StatusKind.recordedOnly:
        return _build(colors.info, colors.infoBackground, 'Recorded only',
            LucideIcons.info);
      case StatusKind.skipped:
        return _build(
          colors.textTertiary,
          colors.surfaceHover,
          'Skipped',
          LucideIcons.minus,
          indeterminate: true,
        );
      case StatusKind.unknown:
        return _unknown(colors);
    }
  }

  static SemanticState _unknown(CsColors colors) => _build(
        colors.severityUnknown,
        colors.surfaceHover,
        'Unknown',
        LucideIcons.circleHelp,
        indeterminate: true,
      );

  static SemanticState _build(
    Color foreground,
    Color background,
    String label,
    IconData icon, {
    bool indeterminate = false,
  }) {
    return SemanticState(
      foreground: foreground,
      background: background,
      border: CsColors.hairline(foreground),
      label: label,
      icon: icon,
      indeterminate: indeterminate,
    );
  }

  static String _normalise(String? raw) =>
      raw?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}
