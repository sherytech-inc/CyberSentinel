# CyberSentinel

CyberSentinel is a Flutter security-monitoring application with live packet
tracing, bounded flow analysis, Dashboard visualizations, an AI Analyst,
Virus Scanner, Threat Intelligence, and Threat Response workflows.

## Presentation architecture

### macOS

```text
Flutter native application
→ managed local FastAPI sidecar
→ TShark/dumpcap packet capture
→ flow analysis and authenticated WebSocket updates
```

### Windows

```text
Flutter Web in Chrome
→ separately running local FastAPI backend
→ local Windows packet capture through Wireshark/Npcap
```

The current presentation build uses ephemeral in-memory capture sessions. The
Dashboard retains its Last Session summary only while the application remains
open. Durable `capture_sessions` database persistence is postponed and is not
required to capture or analyze traffic.

## Requirements

- Flutter stable with Dart 3
- Xcode command-line tools for macOS
- A local checkout of `CyberSentinel-API`
- TShark and dumpcap for native packet capture
- A Supabase project URL and publishable key

Check the installed Flutter version with:

```bash
flutter --version
flutter doctor
```

## Local configuration

Copy the safe template:

```bash
cp config/dev.example.json config/dev.json
```

Set local values in `config/dev.json`. This file is ignored by Git and must
never be committed. Do not place service-role keys, private JWT secrets, Groq
keys, or scanner API keys in the Flutter application.

For managed macOS development, set:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `DESKTOP_BACKEND_MODE` to `managed_source`
- `DESKTOP_BACKEND_PYTHON` to the backend virtual-environment Python
- `DESKTOP_BACKEND_WORKDIR` to the backend checkout

For Chrome, set `API_BASE_URL` to the separately running local backend.

## Install dependencies

```bash
flutter pub get
```

## Run on macOS

```bash
flutter run -d macos --dart-define-from-file=config/dev.json
```

The application starts and owns one managed FastAPI sidecar. Closing the
application terminates that managed process.

## Run in Chrome on Windows

Start the local FastAPI backend first, then run:

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Chrome does not start a native sidecar. Packet capture remains local to the
Windows backend host.

## Validation

```bash
flutter analyze
flutter test
```

Focused presentation tests live under `test/providers`, `test/screens`,
`test/widgets`, and `test/core`.

## Security notes

- Never commit `config/dev.json`, `.env` files, signing material, packet
  captures, logs, uploaded files, or build output.
- The frontend uses only the Supabase publishable key and authenticated user
  sessions.
- Capture-session migration SQL belongs to the backend repository and remains
  unapplied.
