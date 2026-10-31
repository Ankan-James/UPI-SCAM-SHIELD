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