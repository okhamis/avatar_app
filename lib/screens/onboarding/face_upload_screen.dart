import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class FaceUploadScreen extends StatefulWidget {
  const FaceUploadScreen({Key? key}) : super(key: key);

  @override
  State<FaceUploadScreen> createState() => _FaceUploadScreenState();
}

class _FaceUploadScreenState extends State<FaceUploadScreen> {
  int _uploadedCount = 0;

  void _simulateUpload() {
    if (_uploadedCount < 6) {
      setState(() {
        _uploadedCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Let's build your face")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LinearProgressIndicator(value: 2/6),
            const SizedBox(height: 32),
            const Text("Upload 5 to 10 photos of yourself."),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _simulateUpload,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: _simulateUpload,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: List.generate(6, (index) {
                  bool hasImage = index < _uploadedCount;
                  return Container(
                    decoration: BoxDecoration(
                      color: hasImage ? const Color(0xFF5DCAA5).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: hasImage 
                        ? const Icon(Icons.check_circle, color: Color(0xFF5DCAA5))
                        : const Icon(Icons.add_a_photo, color: Colors.grey),
                  );
                }),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadedCount >= 5 ? () => context.goNamed(RouteNames.voiceRecord) : null,
                child: Text(_uploadedCount >= 5 ? "Continue" : "Upload $_uploadedCount/5"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
