# ClipSync

A simple, self-hosted tool for syncing text and links across your devices — no more emailing yourself links or pasting through Discord.

Built as both a real personal tool and a learning project, covering a full stack: a Python/FastAPI backend, a Flutter client, secure credential storage, QR-based device pairing, and full internationalization.

## Features

- 📋 **Shared inbox** — send text or links from any paired device, see them everywhere else
- 🔒 **Secure setup** — credentials stored via OS-level secure storage (Android Keystore / iOS Keychain), never in plain text on disk
- 📱 **QR code pairing** — add a new device by scanning a QR code instead of manually typing a server URL and token
- 🔁 **Short-lived, single-use pairing codes** — QR codes never expose your real access token; codes expire after 2 minutes and can only be redeemed once
- 🗑️ **Swipe to delete** — remove items with a confirmation step, synced across devices
- 📋 **One-tap copy** — copy any message straight to your clipboard
- 🌍 **Full localization** — English and Polish, with automatic detection from your device's language or a manual override
- 🎨 **Dark theme**, per-device color coding, and a clean, distraction-free UI
- ⏱️ **Live relative timestamps** ("2m ago", "Yesterday", etc.), correctly handling your local timezone
- ☁️ **Persistent cloud storage** — backed by PostgreSQL, so your data survives server restarts and redeploys

## Tech stack

**Backend**
- [FastAPI](https://fastapi.tiangolo.com/) (Python)
- [PostgreSQL](https://www.postgresql.org/) hosted on [Neon](https://neon.tech/)
- Deployed on [Render](https://render.com/)
- Token-based authentication

**App**
- [Flutter](https://flutter.dev/) (Dart) — targets Android and iOS
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) for credential storage
- [mobile_scanner](https://pub.dev/packages/mobile_scanner) + [qr_flutter](https://pub.dev/packages/qr_flutter) for QR pairing
- [flutter_localizations](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization) for i18n

## Project structure

```
.
├── backend/            FastAPI backend
│   ├── main.py
│   ├── requirements.txt
│   └── .env.example
└── app/                Flutter client
    ├── lib/
    │   ├── screens/     Setup, home, and QR scan screens
    │   ├── widgets/     Reusable UI components
    │   ├── services/    API client, secure storage
    │   ├── theme/       Colors and theming
    │   ├── utils/       Timestamp formatting, etc.
    │   └── l10n/        Translation files (English, Polish)
    └── pubspec.yaml
```

## Getting started

### Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```
2. Create a `.env` file based on `.env.example`:
   ```
   APP_TOKEN=<a long, random secret>
   DATABASE_URL=<your PostgreSQL connection string>
   ```
3. Run it locally:
   ```bash
   uvicorn main:app --reload
   ```
4. Deploy wherever you like — this project is set up and tested against [Render](https://render.com/)'s free tier with a [Neon](https://neon.tech/) Postgres database, but any standard Python host will work.

### App

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and set up a device or emulator.
2. Navigate to the app directory:
   ```bash
   cd app
   flutter pub get
   ```
3. Run it:
   ```bash
   flutter run
   ```
4. On first launch, you'll be prompted to connect — either enter your server URL and token manually, or scan a pairing QR code generated from an already-connected device.

## How pairing works

Rather than exposing your real access token in a QR code, ClipSync generates a **short-lived, single-use pairing code** on request. The QR encodes just the server URL and this temporary code. Scanning it exchanges the code for your real token, and the code is immediately invalidated — so a photographed or leaked QR code is worthless within minutes, and can't be reused even if captured in time.

## Localization

Currently supported: **English** and **Polish**, selectable from the app's settings menu or automatically detected from your device's language. Contributions for additional languages are welcome — see `app/lib/l10n/` for the translation files.

## License

MIT — see [LICENSE](LICENSE) for details.
