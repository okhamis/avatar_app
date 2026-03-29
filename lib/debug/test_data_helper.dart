import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Helper for loading cached test data during development to speed up iteration.
///
/// Usage:
/// 1. Place your test image at: Documents/presnt_test_photo.jpg
/// 2. Place your test audio at: Documents/presnt_test_voice.wav
/// 3. Call TestDataHelper.loadTestPhoto() and loadTestVoiceRecording()
///
/// This avoids re-uploading photos and re-recording voice on every test cycle.
class TestDataHelper {
  static Future<File?> loadTestPhoto() async {
    if (!kDebugMode) return null;

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final testPhoto = File('${documentsDir.path}/presnt_test_photo.jpg');
      if (await testPhoto.exists()) {
        debugPrint('[TEST] Loaded cached test photo from ${testPhoto.path}');
        return testPhoto;
      }
      debugPrint('[TEST] Test photo not found at ${testPhoto.path}');
      return null;
    } catch (e) {
      debugPrint('[TEST] Error loading test photo: $e');
      return null;
    }
  }

  static Future<File?> loadTestVoiceRecording() async {
    if (!kDebugMode) return null;

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final testVoice = File('${documentsDir.path}/presnt_test_voice.wav');
      if (await testVoice.exists()) {
        debugPrint('[TEST] Loaded cached test voice from ${testVoice.path}');
        return testVoice;
      }
      debugPrint('[TEST] Test voice not found at ${testVoice.path}');
      return null;
    } catch (e) {
      debugPrint('[TEST] Error loading test voice: $e');
      return null;
    }
  }

  /// Get the path where test data should be stored
  static Future<String> getTestDataDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return documentsDir.path;
  }
}
