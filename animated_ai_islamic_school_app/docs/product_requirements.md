# Product Requirements (Draft)

## Vision

Build a premium animated AI Islamic school mobile app where video/avatar quality is the main product experience, with voice/chat as optional interaction modes.

## Goals

- Deliver a trustworthy Islamic teaching experience with high production value visuals.
- Support listening and speaking interactions naturally.
- Provide Quran recitation and educational reading in multiple voices.
- Keep response latency low enough for conversational flow.

## Non-goals

- Building a chat-only assistant.
- Shipping broad social features before core lesson quality is excellent.

## Primary user flows

1. Open app -> choose "Learn with animated teacher".
2. Ask a question by voice -> receive spoken + animated response.
3. Switch to chat input when needed.
4. Start Quran recitation mode -> choose reciter/voice -> listen and follow subtitles.
5. Continue lesson plan and track progress.

## Core functional requirements

- Animated instructor scene with reusable character rigs.
- Voice and text input modes with quick toggle.
- Multilingual responses (at least Arabic + English initially).
- Quran recitation mode with verse navigation.
- Voice selection settings (tone, speed, style).
- Captions/subtitles synced with speech.

## Quality requirements

- Smooth animation and transitions.
- Fast "time to first audio".
- Stable playback under moderate network conditions.
- Clear fallback behavior when media service fails.

## Safety and content requirements

- Guardrails for religious sensitivity and source integrity.
- User-visible disclaimers for educational guidance boundaries.
- Content moderation and abuse prevention.

## Metrics

- Session duration in lesson mode.
- Completion rate per lesson.
- Audio start latency.
- User rating for animation realism and voice quality.
- Retention (D1, D7, D30).
