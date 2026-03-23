class HeyGenService {
  Future<void> trainFaceModel(List<String> imagePaths) async {
    await Future.delayed(const Duration(seconds: 2));
    // Dummy face training
  }

  Future<String> generateAvatarVideo(String text) async {
    await Future.delayed(const Duration(seconds: 1));
    return "dummy_video_url.mp4";
  }
}
