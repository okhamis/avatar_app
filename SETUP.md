# Presnt (AiDigitalTwin) — complete setup

## 1. Prerequisites

- Flutter SDK (see `pubspec.yaml` SDK constraint)
- Firebase project with `google-services` / `GoogleService-Info.plist` / `firebase_options.dart` (already in repo for project `aidigitaltwin-907df`)
- Optional: Node 20+ for Cloud Functions

## 2. Local environment

Copy the template and fill in **real** values (never commit `.env`):

```bash
cp .env.example .env
```

The app loads `.env` from the **project root** when you run `flutter run` (see `lib/bootstrap/load_env.dart`).

### Minimum for a working build

- Firebase already initializes; sign-in needs Auth enabled in Firebase Console.

### Live conversation — pick **one** video provider (Settings → **Live video provider**)

| Provider | Required in `.env` |
|----------|---------------------|
| **D-ID** (default) | `DID_API_KEY` = `API_USERNAME:API_PASSWORD` from [D-ID Studio](https://studio.d-id.com/account-settings) (shown once). `DID_SOURCE_URL` = HTTPS URL to a portrait image. |
| **LiveAvatar** | `LIVEAVATAR_API_KEY`, `LIVEAVATAR_AVATAR_ID` (UUID from [LiveAvatar](https://app.liveavatar.com)). |
| **HeyGen** | `HEYGEN_API_KEY` (+ optional streaming avatar IDs per `.env.example`). |

### Chat brain (Gemini or Claude)

- `BEHAVIOR_LLM=gemini` and `GEMINI_API_KEY` **or**
- `BEHAVIOR_LLM=claude` and `CLAUDE_API_KEY`

### Optional: Gemini **without** putting the key in the app

1. Deploy Cloud Functions: `cd functions && npm install && firebase functions:secrets:set GEMINI_API_KEY`
2. `firebase deploy --only functions`
3. In `.env`: `USE_BACKEND_LLM=true`, `CLOUD_FUNCTIONS_REGION=us-central1`
4. User must be **signed in** with Firebase Auth.

### Voice (optional)

- `ELEVENLABS_API_KEY` for cloned voice / TTS in live modes that use local audio.

## 3. Run

```bash
flutter pub get
flutter run -d macos   # or ios, chrome, etc.
```

Hot restart (**R**) after changing `.env`.

## 4. Cloud Functions (optional)

```bash
cd functions && npm install
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions
```

## 5. Troubleshooting

- **D-ID “Session Failed”**: Check `DID_API_KEY` format (`user:pass` from Studio) and a valid **HTTPS** `DID_SOURCE_URL`.
- **LiveAvatar 4032**: Stale sessions — the app tries to stop active sessions before starting; also check [LiveAvatar](https://app.liveavatar.com) dashboard.
- **No `.env` loaded**: Ensure `.env` exists at repo root or use `assets/.env` with an `assets:` entry in `pubspec.yaml` (optional).
