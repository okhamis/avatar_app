# AiDigitalTwin / Presnt — AI agent context (handoff)

Last updated: 2026-03-27

Use this file together with `.cursor/session-state.md` when picking up work. Do not commit secrets; rotate any key ever pasted in chat.

---

## Authoritative product spec (read this first)

**`Ai DigitalTwin Prompt`** (repo root — note the spaces in the filename) is the **original full prompt**: **Presnt** positioning, **PRODUCT VISION** (look/sound/behave/act/delegate/biometric/family/posthumous), **TECH STACK**, **ENGINEERING RULES**, **REAL VS PLACEHOLDER** guidance, **APP ARCHITECTURE** / folder layout, **DESIGN SYSTEM** colors, **NAVIGATION** (onboarding + 5-tab main app), **SCREEN REQUIREMENTS** (every screen), **KEY DATA MODELS**, **IMPORTANT FLOWS** (approval, tiers), **STORAGE RULES**, and **DELIVERABLES**.

Agents implementing features should treat that file as the **source of truth for use cases and UX intent**, then reconcile with the current codebase where it has evolved (e.g. Gemini is heavily used for behavior; D-ID / LiveAvatar were added for video; some screens from the spec may be partial or renamed).

**Runtime LLM snippets** also live in `lib/config/llm_prompts.dart` (short system strings for Claude/Gemini twins).

---

## Core product intent (short)

From **`Ai DigitalTwin Prompt`**: *Presnt — an AI personal avatar where a digital twin of the user **looks like them, sounds like them, behaves like them**, and **acts on their behalf** when unavailable — with **biometric approval** for sensitive actions, **family access**, and **posthumous continuity**.*

**Bug-tracked separately in `.cursor/session-state.md` (Original Issue):**

> Home screen shows wrong profile photo — not the one user uploaded during onboarding.

**Note:** Root `README.md` is still the default Flutter template — it does not describe the product; use **`Ai DigitalTwin Prompt`** instead.

---

## Stack (concise)

| Area | Details |
|------|---------|
| App | Flutter (macOS heavily used in dev) |
| Backend | Firebase (Auth, Firestore, Storage); optional **Cloud Functions** `behavioralChat` for server-side Gemini |
| State | Riverpod |
| Live video | **Settings → Live video provider**: default **D-ID**; **LiveAvatar**; **HeyGen** (legacy streaming API; sunset ~Mar 2026 → LiveAvatar migration) |
| Voice | ElevenLabs clone + TTS fallback |
| Env | Project root `.env` (see `.env.example`, `SETUP.md`); **full restart** after edits |

---

## Recurring operational issues

1. **Firestore lock** (`LOCK: Resource temporarily unavailable`): only one app instance; quit duplicates; optional remove stale `LOCK` under app container; clearing cache may need **Full Disk Access** for Terminal.
2. **`.env` not picked up**: hot reload insufficient — **hot restart (R)** or full restart.
3. **HeyGen photo avatar `group_id` ≠ streaming `avatar_id`** — do not pass photo group id as streaming session avatar; use `HEYGEN_STREAMING_AVATAR_ID` / defaults for streaming video.
4. **HeyGen quota**: `quota not enough` = billing/credits on HeyGen account.
5. **LiveAvatar 4032**: concurrency — stop stale sessions; free tier often one session.
6. **macOS mic**: voice input may require launching from Xcode for entitlements; text input is the reliable path from CLI.
7. **Security**: vendor API keys have been client-side; `USE_BACKEND_LLM=true` moves Gemini to Functions; App Check + rate limits still recommended for production.

---

## Key files (navigation)

- **`Ai DigitalTwin Prompt`** — original vision, use cases, screens, models, flows (authoritative spec)
- `lib/config/app_config.dart` — feature flags, URLs, env mapping
- `lib/bootstrap/load_env.dart` — `.env` loading
- `lib/screens/conversations/live_conversation_screen.dart` — live chat + video/audio routing
- `lib/services/did_service.dart`, `lib/widgets/did_webrtc_video.dart` — D-ID
- `lib/services/liveavatar_service.dart`, `lib/widgets/heygen_livekit_video.dart` — LiveAvatar / HeyGen LiveKit
- `lib/services/heygen_service.dart`, `lib/services/elevenlabs_service.dart`
- `lib/providers/streaming_settings_provider.dart` — persisted engine choice
- `functions/` — Cloud Functions for Gemini proxy
- `SETUP.md` — setup checklist

---

## D-ID note

Basic auth: `username:password` must be Base64-encoded per HTTP Basic (see `lib/utils/did_auth.dart`). Product docs emphasize **Agents / Agent Sessions** (Realtime); older stream-style APIs may need a planned migration.

---

## Suggested one-line prompt for new chats

> Project: `/Users/okhamis/My Code/AiDigitalTwin` (Presnt). **Read repo root `Ai DigitalTwin Prompt` for vision and use cases.** Then `.cursor/project-handoff.md` (implementation notes) and `.cursor/session-state.md` (recent bugfix log). Flutter + Firebase + Riverpod; live video: default **D-ID**, also LiveAvatar / HeyGen; voice ElevenLabs; LLM Gemini (optional Functions).

---

## Transcript reference (Cursor)

Consolidated from multiple agent sessions; parent transcript UUID for the longest AiDigitalTwin thread: `a62255af-eda8-42ba-a7a3-c814f4758112`.
