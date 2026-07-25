import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cybersentinel/screens/capture_onboarding_screen.dart';
import 'package:cybersentinel/providers/capture_capability_provider.dart';
import 'package:cybersentinel/models/capture_capability.dart';

// We mock the provider for widget testing
class MockCaptureCapabilityProvider extends ChangeNotifier
    implements CaptureCapabilityProvider {
  CaptureCapabilityResult? _capabilityResult;
  bool _isLoading = false;
  String? _error;
  bool _consentGiven = false;
  bool setupValid = false;

  @override
  CaptureCapabilityResult? get capabilityResult => _capabilityResult;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  bool get consentGiven => _consentGiven;

  @override
  bool get consentGranted => _consentGiven;

  @override
  bool get setupCompleted => setupValid;

  @override
  bool get setupPreferenceLoaded => true;

  @override
  String? get selectedInterfaceId => 'en0';

  @override
  bool get isSetupValid => setupValid;

  @override
  bool get hasListeners => super.hasListeners;

  void setResult(CaptureCapabilityResult result) {
    _capabilityResult = result;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void setConsentGiven(bool value) {
    _consentGiven = value;
    notifyListeners();
  }

  @override
  Future<void> fetchCapabilities() async {}

  @override
  Future<void> refreshCapabilities() async {}

  @override
  Future<bool> executeRemediation() async {
    return true;
  }

  @override
  Future<bool> runProbe(String interfaceId) async {
    return true;
  }

  @override
  Future<void> reconfigure() async {
    setupValid = false;
    notifyListeners();
  }

  @override
  Future<void> runDiagnostics() async {}

  @override
  Future<void> resetSetup() async {
    _consentGiven = false;
    setupValid = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('CaptureOnboardingScreen displays loading state initially',
      (WidgetTester tester) async {
    final mockProvider = MockCaptureCapabilityProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<CaptureCapabilityProvider>.value(
            value: mockProvider,
            child: CaptureOnboardingScreen(onReady: () {}),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CaptureOnboardingScreen displays dependencies when ready',
      (WidgetTester tester) async {
    final mockProvider = MockCaptureCapabilityProvider();
    mockProvider.setResult(CaptureCapabilityResult(
      platform: CapturePlatform.macos,
      platformVersion: '14.0',
      architecture: 'arm64',
      tsharkFound: true,
      dumpcapFound: true,
      npcapDetected: false,
      chmodbpfDetected: false,
      bpfDevicesDetected: false,
      interfaces: [
        CaptureInterface(
            id: 'en0',
            systemName: 'en0',
            displayName: 'Wi-Fi',
            isLoopback: false,
            isUp: true,
            addresses: [],
            recommended: true,
            captureAccessible: false)
      ],
      permissionState: CapturePermissionState.permissionRequired,
      captureSupported: false,
      probeState: CaptureProbeState.notRun,
      requiresUserAction: true,
      remediationCode: 'chmodbpf_missing',
      remediationTitle: 'Remediation required',
      remediationMessage: 'Install helper',
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<CaptureCapabilityProvider>.value(
            value: mockProvider,
            child: CaptureOnboardingScreen(onReady: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Network Capture Setup'), findsOneWidget);
    expect(find.text('1. Capture Dependencies'), findsOneWidget);
    expect(find.text('2. System Permissions'), findsOneWidget);
    expect(find.text('3. Select Interface'), findsOneWidget);
    expect(find.text('Copy Installation Command'), findsOneWidget);
    expect(find.text('Run Test Probe'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Run Test Probe'),
          )
          .onPressed,
      isNull,
    );
  });
}
