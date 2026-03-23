# Technical Blueprint (Draft)

## Recommended initial project structure

```text
animated_ai_islamic_school_app/
  mobile_app/                # Flutter app (to be created)
  backend/                   # API orchestration services
  media_pipeline/            # avatar/video/audio generation adapters
  docs/
    product_requirements.md
    technical_blueprint.md
```

## Mobile architecture (Flutter)

- Feature modules:
  - `lesson_experience`
  - `quran_recitation`
  - `input_mode_switch`
  - `voice_profiles`
  - `media_player`
- Shared modules:
  - `core/network`
  - `core/audio`
  - `core/telemetry`
  - `core/error_handling`

## Service interfaces (provider-agnostic)

- `SpeechToTextService`
- `TextToSpeechService`
- `AvatarRenderService`
- `QuranRecitationService`
- `LessonOrchestratorService`

All provider SDK/API integrations should stay behind these interfaces to avoid vendor lock-in.

## Performance constraints

- Prioritize first-frame render speed on lesson screen.
- Stream audio progressively before full media completion where possible.
- Cache reusable animations and static assets locally.

## Deployment notes

- Separate environments: `dev`, `staging`, `prod`.
- CDN distribution for generated media.
- Signed URLs for private audio/video assets.
- Basic observability: request tracing, latency histograms, failure alerts.

## Build roadmap

1. Scaffold Flutter app under `mobile_app`.
2. Implement static animated teacher screen.
3. Add real-time mic capture + STT integration.
4. Add TTS playback and subtitle sync.
5. Integrate first avatar animation renderer.
6. Add recitation mode with verse controls.
