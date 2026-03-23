import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../routes/route_names.dart';

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({Key? key}) : super(key: key);

  @override
  State<VoiceRecordScreen> createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> {
  bool _isRecording = false;
  double _progress = 0.0;
  Timer? _timer;

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _progress = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _progress += 0.01; // Simulates 5 seconds of speaking
        if (_progress >= 1.0) {
          _progress = 1.0;
          _stopRecording();
        }
      });
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isComplete = _progress >= 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Capture Your Voice")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LinearProgressIndicator(value: 3/6),
            const SizedBox(height: 32),
            const Text(
              "Please read the following paragraph aloud to train your digital voice model.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.3)),
              ),
              child: const Text(
                '"I am setting up my Presnt avatar. I want my digital twin to sound exactly like me, so I am providing this voice sample. It will learn my cadence, tone, and inflection to represent me perfectly."',
                style: TextStyle(height: 1.5, fontSize: 18, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            if (_isRecording || _progress > 0) 
              Column(
                children: [
                  LinearProgressIndicator(value: _progress, color: const Color(0xFFE24B4A)),
                  const SizedBox(height: 16),
                  Text(_isRecording ? "Recording..." : "Recording Complete!"),
                ],
              ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.white : const Color(0xFFE24B4A),
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? const Color(0xFFE24B4A) : Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isComplete ? () => context.goNamed(RouteNames.behavioralTraining) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete ? const Color(0xFF5DCAA5) : Colors.grey.withValues(alpha: 0.3),
                  foregroundColor: isComplete ? Colors.black : Colors.white54,
                ),
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
