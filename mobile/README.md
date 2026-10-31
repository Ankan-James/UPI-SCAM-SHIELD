<<<<<<< HEAD
# NUMPE mobile

NUMPE is a simulated UPI-style payments app with an integrated UPI Scam Shield
experience. It does not connect to real banking or UPI infrastructure.

## Current project status

The app currently includes demo onboarding, the dashboard, simulated send and
receive flows, payment review/results, QR generation/scanning, Scam Shield
analysis, searchable activity, scam reporting and session/security settings.
Demo data is visibly labeled. Live integrations use the documented FastAPI
routes where available and do not silently substitute demo payment or analysis
results if a request fails.

The repository does not currently include generated Android platform files or
an installed Flutter/Dart SDK in the development environment. Use Flutter 3.27
or newer (Dart 3.6+) and generate platform scaffolding when the SDK is available:

```powershell
cd mobile
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter test
```

The API adapters match the existing `auth/login`, `auth/register`, `auth/logout`,
`analyze`, `payments/send`, `reports`, and `history` routes. Account, balance,
notification, payment-request, QR and security-lock API contracts are missing
or incomplete on the backend, so this frontend keeps those experiences local
and simulated. The backend analysis response currently omits a dedicated
`explanation` field; the client uses neutral wording when it is absent.
The backend's current security lock routes return acknowledgements but do not
persist a lock state, so the app labels its Emergency Payment Lock as a
session-only client safety gate rather than a server-enforced lock.
=======
# UPI Scam Shield mobile app

Flutter Android client for the UPI Scam Shield API. It supports message/link,
UPI recipient, QR-code, and pasted screenshot-text checks; recent server scan
history; scam-awareness guidance; optional accounts; and read-aloud results.
Screenshot OCR is not implemented, so text must be copied from the screenshot.

## Requirements

- Flutter SDK with Android tooling installed
- Android Studio or an Android device with USB debugging
- The UPI Scam Shield backend running and reachable from the device

## Run on Android

From this directory, fetch dependencies and run the app:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

`10.0.2.2` is the Android emulator's route to the host machine. For a physical
device, use the computer's LAN IP instead, for example
`--dart-define=API_BASE_URL=http://192.168.1.20:8000/api`. The API server must
listen on the LAN interface and the device must be able to reach it. Do not use
the emulator address on a physical device or expose an unencrypted API over an
untrusted network.

The Android runner requests internet and camera permissions. Local HTTP is
enabled only for debug builds; release builds should use HTTPS.

## Backend

From the repository root, start the FastAPI app using the project's configured
Python environment:

```powershell
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

Set `API_BASE_URL` at build/run time to the reachable API root ending in `/api`.
The app's Settings screen displays the configured address and offers a health
check.

## Notes

- Scam checks work without an account. Optional account tokens are stored using
  Android secure storage.
- Before publishing, replace the template Android application ID and configure
  a production signing key; the generated runner uses the default debug signing
  configuration.
- The backend currently exposes shared, recent scan metadata from `/api/history`;
  the app labels it as server-wide, not personal account history.
- Automated analysis can miss scams. Always verify payment requests directly
  with your bank or the intended recipient.
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
