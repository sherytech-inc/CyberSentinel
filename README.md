# CyberSentinel

CyberSentinel is a Flutter security operations workspace for monitoring local
network activity and responding to threats. It combines authenticated
Supabase workflows with a local FastAPI analysis service that handles packet
capture, flow analysis, scanner operations, firewall actions, reporting, and
authenticated real-time updates.

The repository contains the Flutter client. The FastAPI service is a separate
checkout, referred to below as `CyberSentinel-API` or `cybersentinel_api`.

## What is implemented

The application currently includes:

- Supabase email authentication, account creation, password recovery, session
  restoration, and profile bootstrap.
- A dashboard with threat score, traffic summary, packet classification,
  malicious IPs, alert activity, and capture-session state.
- Live packet tracing with capture capability checks and authenticated
  WebSocket updates.
- Firewall log browsing, upload, analysis, and firewall action workflows.
- IP analysis, threat intelligence, investigations, and threat response.
- Virus scanning and scanner result presentation.
- An AI Analyst workspace backed by the local copilot API.
- Reports with authenticated downloads and platform-specific file saving.
- Settings for theme, refresh behavior, and integrations.
- Shared design-system primitives for cards, badges, empty states, loading
  states, metric cards, section headers, and the CyberSentinel logo.

## Runtime architecture

### macOS desktop

```text
Flutter desktop application
  -> managed FastAPI sidecar on 127.0.0.1
  -> packet capture and local analysis
  -> Supabase REST/Auth services
  -> authenticated WebSocket event stream
```

On macOS, `SidecarManager` finds an ephemeral loopback port, creates a local
token, starts the configured backend, waits for `GET /health`, and points
`LocalAgentClient` at that port. When the Flutter process exits, it attempts to
stop the managed backend process as well.

### Chrome and web

```text
 Flutter Web in Chrome
  -> separately running FastAPI backend
  -> Supabase REST/Auth services
```

The web build cannot launch a native process. Start the backend separately and
provide its URL through `API_BASE_URL`. Packet capture therefore runs on the
machine hosting the backend, not inside the browser.

### Authentication and data flow

The Flutter client uses the Supabase publishable key only. The local backend
receives authenticated requests from the client and uses a generated local
sidecar token for loopback service authentication. The client also sends the
Supabase session to the WebSocket service before consuming live state updates.

Capture sessions are currently ephemeral. The dashboard keeps its Last Session
summary while the application is open; durable `capture_sessions` persistence
is not required for the current presentation build.

## Requirements

### All platforms

- Flutter stable with Dart 3
- Dart SDK compatible with the range in `pubspec.yaml`
- A Supabase project with the application schema and authentication enabled
- A local checkout of the matching `CyberSentinel-API` backend

### macOS

- Xcode command-line tools
- Python virtual environment for the backend
- TShark and `dumpcap` for packet capture
- macOS packet-capture permissions where required

### Windows and Chrome

- Chrome
- A separately running FastAPI backend
- Wireshark/Npcap for packet capture on the backend host

Check the local Flutter installation with:

```bash
flutter --version
flutter doctor
```

## Configuration

Create the ignored development configuration from the checked-in template:

```bash
cp config/dev.example.json config/dev.json
```

Edit `config/dev.json` with local values. The file is intentionally ignored by
Git and must not be committed.

### Configuration keys

| Key | Purpose |
| --- | --- |
| `SUPABASE_URL` | Supabase project URL used by Flutter and the backend. |
| `SUPABASE_PUBLISHABLE_KEY` | Browser/desktop-safe Supabase publishable key. |
| `API_BASE_URL` | Backend URL used when the client is not managing a sidecar. |
| `DESKTOP_BACKEND_MODE` | `external`, `managed_source`, or `bundled`. |
| `DESKTOP_BACKEND_PYTHON` | Python executable for `managed_source` mode. |
| `DESKTOP_BACKEND_WORKDIR` | Backend checkout containing `app.main:app`. |
| `BUNDLED_BACKEND_RELATIVE_PATH` | Relative path for a packaged backend executable. |

For managed macOS development, the important values look like this:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_your_key",
  "DESKTOP_BACKEND_MODE": "managed_source",
  "DESKTOP_BACKEND_PYTHON": "/absolute/path/to/cybersentinel_api/venv/bin/python",
  "DESKTOP_BACKEND_WORKDIR": "/absolute/path/to/cybersentinel_api"
}
```

For Chrome, use `external` sidecar behavior and set `API_BASE_URL` to the
already-running backend, for example `http://127.0.0.1:8000`.

The values are compile-time Dart defines. Running without
`--dart-define-from-file=config/dev.json` leaves the authentication values
empty and causes startup validation to fail.

## Install and run

Install Flutter dependencies from the repository root:

```bash
flutter pub get
```

### macOS managed backend

Make sure the backend virtual environment and its dependencies are ready, then
run:

```bash
flutter run -d macos --dart-define-from-file=config/dev.json
```

The expected startup sequence is:

1. Flutter validates Supabase and sidecar configuration.
2. The local FastAPI sidecar starts on an available loopback port.
3. Flutter waits for the sidecar health endpoint.
4. Supabase initializes and restores the current session.
5. The authenticated router opens the login or dashboard workflow.

### Chrome with an external backend

Start the backend separately, verify its health endpoint, and run:

```bash
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Chrome does not start or stop the backend process.

### Useful Flutter run controls

When running interactively:

- `r` applies a hot reload for compatible Dart/UI edits.
- `R` performs a hot restart and recreates application state.
- `d` detaches from Flutter while leaving the application running.
- `q` stops the application and the interactive run.

Use a full restart after changing compile-time defines, platform code, or
startup configuration.

## Application routes

The router protects all operational routes behind authentication:

| Route | Workflow |
| --- | --- |
| `/login` | Email sign-in and optional Google sign-in. |
| `/create-account` | New account registration. |
| `/forgot-password` | Password recovery. |
| `/` | Dashboard and current security posture. |
| `/packet-tracing` | Live capture and packet analysis. |
| `/firewall-logs` | Firewall log and action workflows. |
| `/threat-response` | Threat response actions and audit state. |
| `/virus-scanner` | Scanner setup and scan results. |
| `/ip-analysis` | IP and threat-intelligence analysis. |
| `/reports` | Report generation and downloads. |
| `/ai-analyst` | Copilot-style analyst conversation. |
| `/settings` | Theme, refresh, and integration settings. |
| `/investigation/:id` | Detail view for a selected alert. |

Authentication redirects unauthenticated users to `/login` and sends an
authenticated user away from auth-only routes to the dashboard.

## Client organization

```text
lib/
  main.dart                         Startup, providers, sidecar lifecycle
  app.dart                          Material theme and router host
  core/
    api/                            Local backend HTTP clients
    router/                         GoRouter route and auth redirect setup
    sidecar/                        Native backend process management
    state/                          Cross-workflow coordination
    theme/                          Semantic colors, typography, layout tokens
  models/                            Typed API and UI models
  providers/                         ChangeNotifier workflow state
  screens/                           Auth, dashboard, operations, settings
  services/                          WebSocket and report file services
  widgets/common/                    Shared UI primitives
  widgets/dashboard/                 Dashboard-specific visualizations
```

The main providers are `AuthProvider`, `DashboardProvider`,
`PacketTracingProvider`, `FirewallLogsProvider`, `FirewallActionsProvider`,
`VirusScannerProvider`, `ThreatIntelProvider`, `ThreatResponseProvider`,
`ReportsProvider`, `ChatbotProvider`, `MetricsProvider`,
`CaptureCapabilityProvider`, `IntegrationsProvider`, and `SettingsProvider`.

`LocalAgentClient` centralizes local API requests. `WebSocketService` manages
the authenticated event stream. `CsColors`, `CsTypography`, `CsSpacing`, and
the shared common widgets form the current migration path away from the legacy
static `AppTheme` constants.

## Validation and tests

Run static analysis and the full test suite from the repository root:

```bash
flutter analyze
flutter test
```

The test suite covers:

- Provider state transitions and API mapping.
- Authentication bootstrap and session cleanup behavior.
- Sidecar startup validation and failure codes.
- Local API route and pagination contracts.
- Common widgets and semantic theme behavior.
- Dashboard, settings, capture, firewall, scanner, reports, threat response,
  AI Analyst, and IP analysis screens.
- Dark/light dashboard golden images.

For a faster focused check, run a specific test file:

```bash
flutter test test/core/theme/cs_theme_test.dart
flutter test test/screens/dashboard_screen_test.dart
flutter test test/widgets/common/common_components_test.dart
```

When working on screenshot-sensitive UI, regenerate or inspect the golden
tests deliberately rather than accepting unrelated pixel changes.

## Troubleshooting

### Startup says authentication configuration is missing

Run with the configuration file:

```bash
flutter run -d macos --dart-define-from-file=config/dev.json
```

Check that `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are non-placeholder
values.

### Backend development runtime is missing

Check both paths in `config/dev.json`:

```bash
test -x /absolute/path/to/cybersentinel_api/venv/bin/python
test -d /absolute/path/to/cybersentinel_api
```

The managed backend must expose `app.main:app` and have its dependencies
installed in that virtual environment.

### Supabase cannot be resolved or returns retryable auth errors

Check network/DNS access to the configured Supabase host, then restart the app
after connectivity returns. A successful local sidecar health check does not
guarantee that Supabase authentication is reachable.

### The window looks unchanged after UI edits

Save the file and use `r` for hot reload or `R` for hot restart. If the app was
started from a different checkout or without the defines file, stop it and run
the documented macOS command again. Screens still using legacy `AppTheme`
constants will not automatically change when a new semantic theme token is
added; those screens must be migrated explicitly.

### Backend reports missing columns or tables

Messages such as a `400` for a missing `packets.is_demo` field or a `404` for
the `analyst_notes` table indicate a backend/Supabase schema version mismatch.
Apply the matching backend migrations and verify that the frontend and
`CyberSentinel-API` checkouts are from compatible revisions.

## Security and repository hygiene

- Never commit `config/dev.json`, `.env` files, service-role keys, private JWT
  secrets, scanner keys, signing material, packet captures, logs, uploaded
  files, or build output.
- Use only the Supabase publishable key in Flutter configuration.
- Keep backend secrets in the backend environment, not in Dart defines or the
  client repository.
- Local sidecar tokens are generated per process and redacted from captured
  stderr tails.
- Capture-session migration SQL belongs to the backend repository and remains
  unapplied in this Flutter repository.

## Project status

This is an active development and presentation build. The core workflows are
wired end to end, while backend schema migrations, production packaging, and
durable capture-session persistence remain deployment concerns. Before a
release, validate the matching backend revision, Supabase migrations, packet
capture permissions, and platform-specific signing configuration together.
