import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/threat_response_provider.dart';
import '../../providers/firewall_logs_provider.dart';
import '../../providers/firewall_actions_provider.dart';

enum ThreatActionType {
  block,
  unblock,
  resolve,
  ignore,
}

class StateCoordinator {
  final BuildContext context;

  StateCoordinator(this.context);

  Future<void> afterThreatAction(ThreatActionType action) async {
    final metricsProvider = context.read<MetricsProvider>();
    final threatProvider = context.read<ThreatResponseProvider>();
    final firewallActionsProvider = context.read<FirewallActionsProvider>();

    // Always fetch latest action history after any action.
    await threatProvider.fetchActionHistory();
    // Always fetch latest metrics.
    await metricsProvider.fetchMetrics(silent: true);

    switch (action) {
      case ThreatActionType.block:
      case ThreatActionType.unblock:
        // Firewall rules changed, refresh firewall actions
        await firewallActionsProvider.fetchActions();
        break;
      case ThreatActionType.resolve:
      case ThreatActionType.ignore:
        // Threat queue changed, refresh metrics and threat queue
        await threatProvider.fetchThreatQueue();
        break;
    }
  }
}
