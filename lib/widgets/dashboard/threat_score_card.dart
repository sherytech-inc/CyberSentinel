import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../widgets/common/common.dart';

/// Risk summary for the session currently on screen.
///
/// A session that has not produced a score yet is rendered as Unknown. It must
/// never fall back to a healthy-looking zero, because "no analysis yet" carries
/// no evidence about safety.
class ThreatScoreCard extends StatelessWidget {
  const ThreatScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final colors = CsColors.of(context);
        final text = CsTypography.of(context);

        final showCurrentSession = dashboard.isCurrentSessionVisible;
        final score = showCurrentSession
            ? dashboard.currentSessionThreatScore
            : dashboard.lastSessionThreatScore;
        final hasScore = score != null;
        final displayScore = score ?? 0;

        final state =
            CsSemantics.severity(CsSemantics.severityFromScore(score), colors);
        final accent = hasScore ? state.foreground : colors.textTertiary;

        final statusLabel = !showCurrentSession
            ? 'Monitoring inactive'
            : dashboard.isStopping
                ? 'Finalizing session'
                : hasScore
                    ? state.label
                    : 'Monitoring active — analysis pending';

        final description = hasScore
            ? showCurrentSession
                ? _riskDescription(displayScore)
                : '${_riskDescription(displayScore)} — Last completed session'
            : '';

        return AppCard(
          icon: LucideIcons.shield,
          iconColor: accent,
          title: 'Risk Level',
          trailing: SeverityBadge.fromScore(score, size: CsBadgeSize.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasScore ? '${displayScore.toStringAsFixed(0)} / 100' : 'N/A',
                style: text.metric.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: CsSpacing.xs),
              Text(
                showCurrentSession
                    ? 'Threat Score'
                    : 'Last Session Threat Score',
                style: text.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: CsSpacing.md),
              _ScoreBar(
                score: hasScore ? displayScore : null,
                accent: accent,
                colors: colors,
              ),
              const SizedBox(height: CsSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          text.bodySmall.copyWith(color: colors.textTertiary),
                    ),
                  ),
                  const SizedBox(width: CsSpacing.sm),
                  Expanded(
                    child: Text(
                      description,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium.copyWith(color: accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _riskDescription(int score) {
    if (score >= 70) return 'High Risk Detected';
    if (score >= 40) return 'Warning Risk Detected';
    return 'Low Risk';
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.score,
    required this.accent,
    required this.colors,
  });

  final int? score;
  final Color accent;
  final CsColors colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CsRadius.smallBorder,
      child: Container(
        height: 8,
        color: colors.backgroundTertiary,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: score == null ? 0 : (score! / 100).clamp(0.0, 1.0),
          child: Container(color: accent),
        ),
      ),
    );
  }
}
