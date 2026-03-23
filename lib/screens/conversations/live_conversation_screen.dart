import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LiveConversationScreen extends StatefulWidget {
  const LiveConversationScreen({Key? key}) : super(key: key);

  @override
  State<LiveConversationScreen> createState() => _LiveConversationScreenState();
}

class _LiveConversationScreenState extends State<LiveConversationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final FlutterTts _flutterTts = FlutterTts();
  
  final List<String> messages = [
    "Hey! Are you dealing with the dentist appointment right now?",
    "Yes! I am currently speaking with the receptionist on hold.",
    "Okay, great. Please make sure it's scheduled for Tuesday after 3 PM.",
    "Understood. I will confirm the Tuesday afternoon slot and notify you when done."
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    _initAndSpeak();
  }

  Future<void> _initAndSpeak() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ]);
        
    // Wait for UI to render
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Speak first avatar message
    await _flutterTts.speak(messages[0]);
    
    // Simulate back and forth interaction
    await Future.delayed(const Duration(seconds: 4));
    await _flutterTts.speak(messages[2]);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Session"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text("04:32", style: TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0A),
              border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated pulse rings
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 100 + (_controller.value * 50),
                      height: 100 + (_controller.value * 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF5DCAA5).withValues(alpha: 0.1),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 130 + (_controller.value * 30),
                      height: 130 + (_controller.value * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7F77DD).withValues(alpha: 0.15),
                      ),
                    );
                  },
                ),
                // Core Avatar Image placeholder
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF7F77DD),
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const Positioned(
                  bottom: 16,
                  child: Text(
                    "HeyGen Video Stream (Simulated)",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isAvatar = index % 2 == 0;
                return Align(
                  alignment: isAvatar ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isAvatar ? const Color(0xFF1A1A1A) : const Color(0xFF7F77DD).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isAvatar ? const Radius.circular(16) : const Radius.circular(0),
                        bottomLeft: isAvatar ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    child: Text(messages[index], style: const TextStyle(fontSize: 15, height: 1.4)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE24B4A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("End Session"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text("Take Over"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
