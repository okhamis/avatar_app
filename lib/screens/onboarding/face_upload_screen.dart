import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/route_names.dart';

class FaceUploadScreen extends StatefulWidget {
  const FaceUploadScreen({Key? key}) : super(key: key);

  @override
  State<FaceUploadScreen> createState() => _FaceUploadScreenState();
}

class _FaceUploadScreenState extends State<FaceUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];

  Future<void> _pickGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images);
          if (_photos.length > 6) {
            _photos.removeRange(6, _photos.length);
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _pickCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && _photos.length < 6) {
        setState(() {
          _photos.add(photo);
        });
      }
    } catch (e) {
      // Fallback to gallery if camera is unsupported on this platform (e.g. macOS)
      return _pickGallery();
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
                  onPressed: _pickCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: _pickGallery,
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
                  bool hasImage = index < _photos.length;
                  return Container(
                    decoration: BoxDecoration(
                      color: hasImage ? const Color(0xFF5DCAA5).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.hardEdge,
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
                onPressed: _photos.length >= 5 ? () => context.goNamed(RouteNames.voiceRecord) : null,
                child: Text(_photos.length >= 5 ? "Continue" : "Upload ${_photos.length}/5"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
