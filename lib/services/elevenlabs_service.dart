class ElevenLabsService {
  Future<void> cloneVoice(String audioFilePath) async {
    await Future.delayed(const Duration(seconds: 2));
    // Dummy clone logic
  }

  Future<String> generateSpeech(String text) async {
    await Future.delayed(const Duration(seconds: 1));
    return "dummy_audio_path.mp3";
  }
}
