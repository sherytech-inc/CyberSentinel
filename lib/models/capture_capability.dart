enum CapturePlatform { macos, windows, linux, unsupported }

enum CaptureDependencyState {
  available,
  missing,
  incompatible,
  inaccessible,
  unknown
}

enum CapturePermissionState {
  notChecked,
  permissionRequired,
  actionRequired,
  granted,
  denied,
  unsupported,
  error
}

enum CaptureProbeState { notRun, running, passed, failed, timedOut }

class CaptureInterface {
  final String id;
  final String systemName;
  final String displayName;
  final String? description;
  final String? interfaceType;
  final bool isLoopback;
  final bool isUp;
  final List<String> addresses;
  final bool recommended;
  final bool captureAccessible;

  CaptureInterface({
    required this.id,
    required this.systemName,
    required this.displayName,
    this.description,
    this.interfaceType,
    required this.isLoopback,
    required this.isUp,
    required this.addresses,
    required this.recommended,
    required this.captureAccessible,
  });

  factory CaptureInterface.fromJson(Map<String, dynamic> json) {
    return CaptureInterface(
      id: json['id'] as String,
      systemName: json['system_name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      interfaceType: json['interface_type'] as String?,
      isLoopback: json['is_loopback'] as bool? ?? false,
      isUp: json['is_up'] as bool? ?? false,
      addresses: List<String>.from(json['addresses'] ?? []),
      recommended: json['recommended'] as bool? ?? false,
      captureAccessible: json['capture_accessible'] as bool? ?? false,
    );
  }
}

class CaptureCapabilityResult {
  final CapturePlatform platform;
  final String platformVersion;
  final String architecture;

  final bool tsharkFound;
  final String? tsharkPath;
  final String? tsharkVersion;

  final bool dumpcapFound;
  final String? dumpcapPath;
  final String? dumpcapVersion;

  final bool npcapDetected;
  final String? npcapVersion;
  final bool chmodbpfDetected;
  final bool bpfDevicesDetected;

  final List<CaptureInterface> interfaces;
  final String? recommendedInterface;

  final CapturePermissionState permissionState;
  final bool captureSupported;
  final CaptureProbeState probeState;

  final String? remediationCode;
  final String? remediationTitle;
  final String? remediationMessage;
  final bool requiresUserAction;
  final DateTime? lastCheckedAt;

  CaptureCapabilityResult({
    required this.platform,
    required this.platformVersion,
    required this.architecture,
    required this.tsharkFound,
    this.tsharkPath,
    this.tsharkVersion,
    required this.dumpcapFound,
    this.dumpcapPath,
    this.dumpcapVersion,
    required this.npcapDetected,
    this.npcapVersion,
    required this.chmodbpfDetected,
    required this.bpfDevicesDetected,
    required this.interfaces,
    this.recommendedInterface,
    required this.permissionState,
    required this.captureSupported,
    required this.probeState,
    this.remediationCode,
    this.remediationTitle,
    this.remediationMessage,
    required this.requiresUserAction,
    this.lastCheckedAt,
  });

  factory CaptureCapabilityResult.fromJson(Map<String, dynamic> json) {
    return CaptureCapabilityResult(
      platform: _parsePlatform(json['platform'] as String?),
      platformVersion: json['platform_version'] as String? ?? '',
      architecture: json['architecture'] as String? ?? '',
      tsharkFound: json['tshark_found'] as bool? ?? false,
      tsharkPath: json['tshark_path'] as String?,
      tsharkVersion: json['tshark_version'] as String?,
      dumpcapFound: json['dumpcap_found'] as bool? ?? false,
      dumpcapPath: json['dumpcap_path'] as String?,
      dumpcapVersion: json['dumpcap_version'] as String?,
      npcapDetected: json['npcap_detected'] as bool? ?? false,
      npcapVersion: json['npcap_version'] as String?,
      chmodbpfDetected: json['chmodbpf_detected'] as bool? ?? false,
      bpfDevicesDetected: json['bpf_devices_detected'] as bool? ?? false,
      interfaces: (json['interfaces'] as List?)
              ?.map((e) => CaptureInterface.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendedInterface: json['recommended_interface'] as String?,
      permissionState:
          _parsePermissionState(json['permission_state'] as String?),
      captureSupported: json['capture_supported'] as bool? ?? false,
      probeState: _parseProbeState(json['probe_state'] as String?),
      remediationCode: json['remediation_code'] as String?,
      remediationTitle: json['remediation_title'] as String?,
      remediationMessage: json['remediation_message'] as String?,
      requiresUserAction: json['requires_user_action'] as bool? ?? false,
      lastCheckedAt: json['last_checked_at'] != null
          ? DateTime.tryParse(json['last_checked_at'] as String)
          : null,
    );
  }

  static CapturePlatform _parsePlatform(String? val) {
    switch (val) {
      case 'macos':
        return CapturePlatform.macos;
      case 'windows':
        return CapturePlatform.windows;
      case 'linux':
        return CapturePlatform.linux;
      default:
        return CapturePlatform.unsupported;
    }
  }

  static CapturePermissionState _parsePermissionState(String? val) {
    switch (val) {
      case 'permissionRequired':
        return CapturePermissionState.permissionRequired;
      case 'actionRequired':
        return CapturePermissionState.actionRequired;
      case 'granted':
        return CapturePermissionState.granted;
      case 'denied':
        return CapturePermissionState.denied;
      case 'error':
        return CapturePermissionState.error;
      case 'notChecked':
        return CapturePermissionState.notChecked;
      default:
        return CapturePermissionState.unsupported;
    }
  }

  static CaptureProbeState _parseProbeState(String? val) {
    switch (val) {
      case 'running':
        return CaptureProbeState.running;
      case 'passed':
        return CaptureProbeState.passed;
      case 'failed':
        return CaptureProbeState.failed;
      case 'timedOut':
        return CaptureProbeState.timedOut;
      default:
        return CaptureProbeState.notRun;
    }
  }
}
