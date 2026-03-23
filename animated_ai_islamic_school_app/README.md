# Animated AI Islamic School App

This is a separate app workspace for a mobile-first "animated AI Islamic school" product.

## Product direction

- Primary experience: high-quality animated teacher/avatar with strong video presentation.
- Secondary experience: user can switch between voice and chat responses.
- Core capabilities:
  - Teach lessons interactively.
  - Listen to users and answer.
  - Recite Quran with high-quality audio.
  - Read content in different selectable voices.
- Not chat-first: chat is optional support, while animation and media quality are the main value.

## Suggested tech stack (mobile + media first)

- **Mobile app:** Flutter (keeps consistency with your current stack).
- **Animation runtime:** Rive + Lottie for app-native motion and interactions.
- **Video/avatar generation service:** external AI media service (provider can be chosen later).
- **Speech-to-text:** streaming ASR service for live listening.
- **Text-to-speech:** neural TTS with multiple voices and Arabic support.
- **Audio engine:** low-latency player/recorder with waveform + ducking support.
- **Backend orchestration:** lightweight API gateway + session orchestration.
- **Storage/CDN:** object storage for generated video/audio assets + fast streaming.

## High-level architecture

1. User speaks or types.
2. Input is transcribed (if voice) and routed to lesson engine.
3. Lesson engine generates structured response text + recitation directives.
4. TTS/recitation pipeline generates audio in selected voice.
5. Avatar/video renderer synchronizes lip/gesture animation with audio.
6. Mobile app streams final media with optional subtitle/chat transcript.

## MVP phases

### Phase 1 (4-6 weeks)

- Basic animated teacher screen.
- Voice input + text input switching.
- Arabic/English lesson responses.
- Quran recitation playback in at least 2 voices.
- Basic quality controls (speed, voice, subtitle on/off).

### Phase 2

- Better animation realism and camera presets.
- Lesson tracks (beginner/intermediate).
- Parent/student profiles and progress tracking.
- Downloadable lesson clips.

### Phase 3

- Personalized curriculum engine.
- Real-time classroom mode for groups.
- Advanced moderation and safe-content pipelines.

## Immediate next build tasks

1. Create a fresh Flutter app in this folder.
2. Implement media-focused home screen (animated teacher first).
3. Add voice input and TTS output service abstraction.
4. Integrate a first avatar/video provider behind an interface.
5. Add Quran recitation module with selectable reciters/voices.

## Notes

- Keep media generation provider-agnostic through interfaces.
- Optimize for perceived quality: smooth animation, low latency audio start, stable streaming.
- Design for compliance and respectful religious content governance from day one.
