upi-scam-shield/
│
├── website/ # Website + APK downloads
│ ├── index.html
│ ├── pages/
│ │ ├── about.html
│ │ ├── download.html
│ │ ├── login.html
│ │ └── privacy-policy.html
│ ├── css/
│ │ └── style.css
│ ├── js/
│ │ ├── main.js
│ │ ├── analytics.js
│ │ └── auth.js
│ └── assets/
│
├── mobile/ # Flutter Android application
│ ├── android/
│ ├── assets/
│ │ ├── images/
│ │ ├── icons/
│ │ └── audio/
│ ├── lib/
│ │ ├── main.dart
│ │ ├── app.dart
│ │ ├── screens/
│ │ │ ├── splash_screen.dart
│ │ │ ├── login_screen.dart
│ │ │ ├── register_screen.dart
│ │ │ ├── home_screen.dart
│ │ │ ├── scan_screen.dart
│ │ │ ├── result_screen.dart
│ │ │ ├── screenshot_screen.dart
│ │ │ ├── qr_scanner_screen.dart
│ │ │ ├── history_screen.dart
│ │ │ ├── awareness_screen.dart
│ │ │ └── settings_screen.dart
│ │ ├── widgets/
│ │ │ ├── risk_badge.dart
│ │ │ ├── scan_result_card.dart
│ │ │ ├── voice_player.dart
│ │ │ └── loading_indicator.dart
│ │ ├── services/
│ │ │ ├── api_service.dart
│ │ │ ├── auth_service.dart
│ │ │ ├── scan_service.dart
│ │ │ └── voice_service.dart
│ │ ├── models/
│ │ │ ├── user.dart
│ │ │ └── scan_result.dart
│ │ ├── utils/
│ │ │ ├── constants.dart
│ │ │ └── validators.dart
│ │ └── theme/
│ │ └── app_theme.dart
│ ├── test/
│ ├── pubspec.yaml
│ └── README.md
│
├── backend/ # Python + FastAPI server
│ ├── app/
│ │ ├── main.py
│ │ ├── config.py
│ │ ├── api/
│ │ │ └── routes/
│ │ │ ├── auth.py
│ │ │ ├── analytics.py
│ │ │ ├── analyze.py
│ │ │ ├── history.py
│ │ │ ├── reports.py
│ │ │ └── voice.py
│ │ ├── services/
│ │ │ ├── auth_service.py
│ │ │ ├── analytics_service.py
│ │ │ ├── agent_service.py
│ │ │ └── voice_service.py
│ │ ├── database/
│ │ │ ├── connection.py
│ │ │ ├── models.py
│ │ │ └── migrations/
│ │ └── security/
│ │ ├── password.py
│ │ └── sessions.py
│ ├── tests/
│ ├── requirements.txt
│ └── .env.example
│
├── agent/ # AI scam detection
│ ├── __init__.py
│ ├── agent.py
│ ├── gemma_client.py
│ ├── prompt_templates.py
│ ├── detection/
│ │ ├── text_analyzer.py
│ │ ├── url_analyzer.py
│ │ ├── scam_patterns.py
│ │ └── risk_scorer.py
│ ├── tools/
│ │ ├── url_checker.py
│ │ └── text_preprocessor.py
│ └── evaluation/
│ ├── test_cases.json
│ └── evaluate.py
│
├── database/ # Database documentation/schema
│ └── schema.sql
│
├── docs/
│ ├── API_CONTRACT.md
│ ├── DATABASE_SCHEMA.md
│ └── SETUP.md
│
├── .env.example
├── .gitignore
└── README.md
