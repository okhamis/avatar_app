# Test Data Setup for Faster Iteration

When testing the avatar onboarding flow, you don't need to upload a new photo and record a new voice each time. Use cached test data instead.

## Setup (One-time)

1. **Save a test photo:**
   - Use a photo of yourself (or any test image)
   - Copy it to: `~/Documents/presnt_test_photo.jpg`
   - The app will automatically detect and load it on the Face Upload screen

2. **Save a test voice:**
   - Record a short voice sample (3-10 seconds) or use an existing voice file
   - Convert/save it as: `~/Documents/presnt_test_voice.wav`
   - The app will automatically detect and load it on the Voice Record screen

## How It Works

- When the app is in **debug mode**, it automatically looks for these files
- If found, they're auto-loaded so you skip the upload/record step
- The files are only loaded in debug builds (not in release)

## Quick Testing Flow (After Setup)

1. Launch the app in debug mode: `flutter run`
2. Create account or sign in
3. Toggle to **Custom Mode** in Settings (very important!)
4. Click "Build your avatar" or go through welcome flow
5. **Face Upload screen** → Test photo auto-loads → Click Continue
6. **Voice Record screen** → Test voice auto-loads → Click Continue
7. **Behavioral Training** → Enter personality → Click Continue
8. **Avatar Preview** → Should show YOUR avatar (not pre-trained)
9. **Go Live** → Should stream YOUR custom avatar

## Troubleshooting

### Getting wrong avatar/voice (pre-trained instead of custom)
- Check Settings: Is **Custom Mode** actually enabled? (The toggle should show "Create a custom avatar...")
- Log out completely and log back in
- Make sure the Custom mode toggle actually saved

### Test photo/voice not loading
- Files must be exact names: `presnt_test_photo.jpg` and `presnt_test_voice.wav`
- Files must be in `~/Documents/` (the app's documents directory)
- Check console logs for `[TEST]` messages indicating file loading

### File not found errors
- Make sure the file path is exactly: `~/Documents/presnt_test_photo.jpg`
- On macOS, this is your user's Documents folder, not the project directory
