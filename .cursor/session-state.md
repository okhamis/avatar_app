# AiDigitalTwin — Session State

Last updated: 2026-03-27 (see also `.cursor/project-handoff.md` for consolidated AI context)

**Product vision & use cases:** repo root file **`Ai DigitalTwin Prompt`** (full original spec: screens, models, flows).

## Original Issue
Home screen shows wrong profile photo — not the one user uploaded during onboarding.

## Root Cause
`previewImagePath` in Firestore stored a temporary local file path (from image picker). After restart, that path could be stale/wrong/missing.

## Code Changes Made

### 1. Avatar preview upload to Firebase Storage
- **Files:** `lib/providers/avatar_provider.dart`, `lib/services/firebase_service.dart`
- Added `firebase_storage` dependency
- `saveFaceDraft()` and `finalizeAvatar()` now:
  - Copy picked image to app documents (`avatar_preview_<uid>.jpg`)
  - Upload to Storage at `avatars/<uid>/preview.jpg`
  - Save HTTPS download URL to Firestore `previewImagePath`

### 2. Removed mock auth fallbacks
- **File:** `lib/providers/auth_provider.dart`
- Removed all `mock_` user creation in debug mode
- Login, createAccount, Google, Facebook all fail with real errors now

### 3. Disabled Firebase emulator by default
- **File:** `lib/config/app_config.dart`
- `useFirebaseEmulator` defaults to `false` (was `true`)

### 4. Added "Sign in" link on create account screen
- **File:** `lib/screens/onboarding/create_account_screen.dart`
- "Already have an account? Sign in" → navigates to existing `signIn` route

### 5. macOS keychain entitlement
- **Files:** `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements`
- Added `keychain-access-groups` with empty array (required by Firebase Auth on macOS)
- User enabled Development Signing in Xcode (Team: Omar Abou-Khamis Personal Team)

### 6. Added Sign Out to Settings
- **File:** `lib/screens/settings/avatar_setup_screen.dart`
- Red "Sign Out" option at bottom of settings list

### 7. Fixed ApprovalNotifier late final crash
- **File:** `lib/providers/approval_provider.dart`
- Changed `late final` fields to getters (`ref.read(...)`) to avoid `LateError._throwFieldAlreadyInitialized` on rebuild

### 8. Fixed avatar preview UX
- **File:** `lib/screens/onboarding/avatar_preview_screen.dart`
- Removed fake play button → replaced with "Live video unlocks after Go Live" label
- Changed "RENDERING LIVE" → "PREVIEW READY"

### 9. Fixed RenderFlex overflow in glass bar
- **File:** `lib/widgets/presnt/presnt_glass_bar.dart`
- Changed fixed `SizedBox(width: 120)` to `Flexible` for actions area

### 10. Fixed flutter_tts crash on macOS
- **File:** `lib/screens/conversations/live_conversation_screen.dart`
- `setSharedInstance()` is iOS-only; wrapped with `Platform.isIOS` check

### 11. Google Sign-In error handling
- **File:** `lib/providers/auth_provider.dart`
- Added explicit error message when `GIDClientID` missing from Info.plist

## Firebase Console Setup (done by user)
- Email/Password auth provider: **enabled**
- Storage bucket: **created** (`gs://aidigitaltwin-907df.firebasestorage.app`)
- Storage rules: **NOT YET UPDATED** — still `allow read, write: if false`
- Development Signing: **enabled** in Xcode (Personal Team)

## Current State
- User was able to sign in with real Firebase Auth (Email/Password)
- App crashed on Home due to ApprovalNotifier `late final` bug → **fixed**
- App crashed on Live Conversation due to `flutter_tts` macOS issue → **fixed**
- Build cache permission error on hot reload → need `flutter clean && flutter pub get && flutter run`

## Pending Tasks (in priority order)
1. **Run clean build** — `flutter clean && flutter pub get && flutter run`
2. **Publish Storage rules** — replace `if false` with:
   ```
   match /avatars/{userId}/preview.jpg {
     allow read, write: if request.auth != null && request.auth.uid == userId;
   }
   ```
3. **Verify end-to-end** — sign in → face upload → check Storage Files → confirm Home photo
4. **Google Sign-In macOS config** — add GIDClientID + REVERSED_CLIENT_ID to macOS Info.plist
5. **Dependency upgrades** — `flutter pub outdated` then staged upgrades

## Completed Tasks
- ~~Resolve keychain signing~~ (done via Xcode Development Signing)
- ~~Fix RenderFlex overflow~~ in presnt_glass_bar.dart
- ~~Fix avatar preview UX~~ (fake play button removed)
- ~~Fix ApprovalNotifier crash~~ (late final → getters)
- ~~Fix flutter_tts macOS crash~~ (Platform.isIOS guard)
- ~~Add Sign Out to settings~~
- ~~Add "Already have an account? Sign in" link~~
- ~~Remove mock auth fallbacks~~
- ~~Disable Firebase emulator default~~

## Test Status
- `flutter analyze`: clean (3 pre-existing unused-import warnings in unrelated files)
- `flutter test`: all 5 tests pass

## Key Files
- `lib/providers/avatar_provider.dart` — avatar state + preview upload logic
- `lib/providers/auth_provider.dart` — auth (no more mock fallback)
- `lib/providers/approval_provider.dart` — fixed late final crash
- `lib/services/firebase_service.dart` — Firestore + Storage operations
- `lib/screens/home/home_screen.dart` — uses `avatar.previewImagePath` for background
- `lib/screens/onboarding/avatar_preview_screen.dart` — fixed preview UX
- `lib/screens/conversations/live_conversation_screen.dart` — fixed TTS crash
- `lib/screens/settings/avatar_setup_screen.dart` — added sign out
- `lib/config/app_config.dart` — emulator toggle + all config
- `lib/widgets/presnt/presnt_glass_bar.dart` — fixed overflow
- `macos/Runner/DebugProfile.entitlements` — keychain entitlement
- `macos/Runner/Release.entitlements` — keychain entitlement
