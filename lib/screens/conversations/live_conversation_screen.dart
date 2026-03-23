import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/avatar_provider.dart';
import '../../providers/approval_provider.dart';
import '../../theme/presnt_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveConversationScreen extends ConsumerStatefulWidget {
  const LiveConversationScreen({super.key});

  @override
  ConsumerState<LiveConversationScreen> createState() => _LiveConversationScreenState();
}

class _LiveConversationScreenState extends ConsumerState<LiveConversationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _sessionActive = true;
  Duration _elapsed = Duration.zero;
  Timer? _durationTimer;
  bool _showApprovalBanner = false;

  static const _bgUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=1200&h=1600&fit=crop';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionActive && mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setSharedInstance(true);
    await Future.delayed(const Duration(milliseconds: 600));
    _addMessage('Hello. I am your Presnt avatar. How can I help today?', isAvatar: true);
  }

  void _addMessage(String text, {required bool isAvatar}) {
    setState(() {
      _messages.add({'text': text, 'isAvatar': isAvatar, 'time': DateTime.now()});
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
    if (isAvatar) _flutterTts.speak(text);
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || !_sessionActive) return;
    _msgController.clear();
    _addMessage(text, isAvatar: false);

    final lower = text.toLowerCase();
    final needsApproval = lower.contains('ssn') ||
        lower.contains('password') ||
        lower.contains('bank') ||
        lower.contains('address') ||
        lower.contains('credit card');
    if (needsApproval) {
      setState(() => _showApprovalBanner = true);
      await ref.read(pendingApprovalsProvider.notifier).mockIncomingRequest('acc_demo', 'sess_live', '****-****-9022');
    }

    setState(() => _isTyping = true);
    final llm = ref.read(behavioralLlmProvider);
    final response = await llm.generateBehavioralResponse(text);
    if (mounted) {
      setState(() => _isTyping = false);
      _addMessage(response, isAvatar: true);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endSession() {
    setState(() => _sessionActive = false);
    _durationTimer?.cancel();
    _flutterTts.stop();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pulse.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _bgUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => Container(color: Colors.black),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _blurOrb(PresntTokens.primary.withValues(alpha: 0.12), 220),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _blurOrb(PresntTokens.secondary.withValues(alpha: 0.1), 180),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRESNT',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: PresntTokens.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: PresntTokens.secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Color(0x806EDAB4), blurRadius: 8)],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE SESSION · ${_formatDuration(_elapsed)}',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                  color: PresntTokens.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: PresntTokens.secondary, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI PROXY ACTIVE',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {},
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.25),
                            ),
                            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        final v = _pulse.value;
                        return SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120 + v * 24,
                                height: 120 + v * 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: PresntTokens.primary.withValues(alpha: 0.22)),
                                ),
                              ),
                              Container(
                                width: 100 + v * 18,
                                height: 100 + v * 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: PresntTokens.secondary.withValues(alpha: 0.2)),
                                ),
                              ),
                              const Icon(Icons.graphic_eq_rounded, color: Colors.white24, size: 48),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                if (_showApprovalBanner)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: PresntTokens.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.verified_user_rounded, color: PresntTokens.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Credential verification',
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Participant requesting approval',
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _showApprovalBanner = false),
                                child: Text('Dismiss', style: GoogleFonts.inter(fontSize: 11, color: PresntTokens.primary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                SizedBox(
                  height: 160,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                        ],
                        stops: const [0.0, 0.15, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isTyping) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Avatar is thinking…',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: PresntTokens.primary.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }
                        final msg = _messages[index];
                        final isAvatar = msg['isAvatar'] as bool;
                        final text = msg['text'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: isAvatar ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                            children: [
                              Text(
                                isAvatar ? 'AI PROXY' : 'PARTICIPANT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  color: isAvatar ? PresntTokens.secondary : Colors.white38,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isAvatar ? 4 : 18),
                                  bottomRight: Radius.circular(isAvatar ? 18 : 4),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                                    decoration: BoxDecoration(
                                      color: isAvatar
                                          ? PresntTokens.primary.withValues(alpha: 0.12)
                                          : Colors.white.withValues(alpha: 0.08),
                                      border: Border.all(
                                        color: isAvatar
                                            ? PresntTokens.primary.withValues(alpha: 0.25)
                                            : Colors.white.withValues(alpha: 0.06),
                                      ),
                                    ),
                                    child: Text(
                                      text,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isAvatar ? PresntTokens.primary : Colors.white.withValues(alpha: 0.92),
                                        fontStyle: isAvatar ? FontStyle.italic : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          enabled: _sessionActive,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Message…',
                            hintStyle: TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sessionActive ? _sendMessage : null,
                        style: IconButton.styleFrom(
                          backgroundColor: PresntTokens.primary,
                          foregroundColor: PresntTokens.onPrimaryFixed,
                        ),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _sessionActive
                                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('You have taken over the session.')),
                                          )
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.switch_account_rounded, color: PresntTokens.primary, size: 22),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Take Over',
                                          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.mic_none_rounded, color: Colors.white70),
                            ),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.videocam_outlined, color: Colors.white70),
                            ),
                            const SizedBox(width: 4),
                            Material(
                              color: PresntTokens.errorContainer.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _endSession,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.call_end_rounded, color: PresntTokens.error, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        'END',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          color: PresntTokens.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurOrb(Color c, double r) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
      child: Container(width: r, height: r, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
    );
  }
}
