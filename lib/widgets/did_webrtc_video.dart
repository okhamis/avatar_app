import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/did_service.dart';

class DidWebrtcVideo extends StatefulWidget {
  const DidWebrtcVideo({
    super.key,
    required this.didService,
    this.fillScreen = false,
    this.sourceUrl,
    this.voiceId,
    this.voiceProvider,
  });

  final DidService didService;
  final bool fillScreen;

  /// When non-null, uses the Talks/Streams API with this face photo URL (Custom Pipeline).
  final String? sourceUrl;

  /// ElevenLabs cloned voice ID for Custom Pipeline. Passed to sendTask.
  final String? voiceId;

  /// Voice provider override (e.g. 'elevenlabs'). Defaults to 'microsoft' in Studio mode.
  final String? voiceProvider;

  @override
  DidWebrtcVideoState createState() => DidWebrtcVideoState();
}

class DidWebrtcVideoState extends State<DidWebrtcVideo> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  String? streamId;
  String? sessionId;
  String _status = 'Connecting...';
  bool _isConnected = false;
  bool _initialized = false;
  Size? _videoSize;
  Timer? _dimensionPoller;

  /// True when WebRTC video is flowing (not while showing status / error).
  bool get isStreamReady => _isConnected && streamId != null && sessionId != null;

  /// UI / snackbar: current phase (Connecting…, errors, Connected before video track).
  String get statusHint => _status;

  @override
  void initState() {
    super.initState();
    _initWebrtc();
  }

  Future<void> _initWebrtc() async {
    await _renderer.initialize();
    _initialized = true;

    try {
      final isCustom = widget.sourceUrl != null && widget.sourceUrl!.isNotEmpty;
      debugPrint('[WebRTC] Starting — mode=${isCustom ? "custom" : "studio"} sourceUrl=${widget.sourceUrl ?? "null"}');

      final sessionData = isCustom
          ? await widget.didService.createCustomStream(sourceUrl: widget.sourceUrl!)
          : await widget.didService.createStream();

      debugPrint('[WebRTC] createStream response: ${sessionData == null ? "NULL — lastError=${widget.didService.lastError}" : "OK id=${sessionData["id"]}"}');

      if (sessionData == null || !mounted) {
        setState(() => _status = 'D-ID Session Failed: ${widget.didService.lastError ?? "null response"}');
        return;
      }

      final sid = sessionData['id'];
      final sessid = sessionData['session_id'];
      // Agents API returns `jsep`; legacy API returned `offer` — handle both.
      final jsep = sessionData['jsep'] ?? sessionData['offer'];
      final rawIceServers = sessionData['ice_servers'];

      debugPrint('[WebRTC] session id=$sid session_id=$sessid jsep=${jsep != null ? "present" : "MISSING"} iceServers=${rawIceServers?.length ?? 0}');

      if (sid == null || sessid == null || jsep == null) {
        setState(() => _status = 'Invalid D-ID stream response (missing id/session_id/jsep)');
        return;
      }

      streamId = sid;
      sessionId = sessid;

      // Use ICE servers provided by D-ID when available; fall back to Google STUN.
      final iceServers = (rawIceServers is List && rawIceServers.isNotEmpty)
          ? rawIceServers
          : [
              {'urls': 'stun:stun.l.google.com:19302'},
            ];

      _peerConnection = await createPeerConnection({'iceServers': iceServers});

      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          widget.didService.submitIceCandidate(
            streamId: streamId!,
            sessionId: sessionId!,
            candidate: candidate.candidate!,
            sdpMid: candidate.sdpMid ?? '0',
            sdpMLineIndex: candidate.sdpMLineIndex ?? 0,
          );
        }
      };

      _peerConnection!.onTrack = (event) {
        debugPrint('[WebRTC] onTrack kind=${event.track.kind}');
        if (event.track.kind == 'video') {
          _renderer.srcObject = event.streams[0];
          debugPrint('[WebRTC] Video track received — avatar should appear');
          if (mounted) {
            setState(() {
              _isConnected = true;
              _status = 'Connected';
            });
            // Talks/Streams API requires a speak task to start rendering video.
            // Send a silent warmup so the avatar face appears immediately.
            Future.delayed(const Duration(milliseconds: 500), () {
              if (streamId != null && sessionId != null) {
                debugPrint('[WebRTC] Sending warmup speak task to render face');
                widget.didService.sendTask(
                  streamId: streamId!,
                  sessionId: sessionId!,
                  text: 'Hello.',
                  voiceProvider: widget.voiceProvider,
                  voiceId: widget.voiceId,
                );
              }
            });
            // Poll for video dimensions — available after first frame renders.
            _dimensionPoller = Timer.periodic(const Duration(milliseconds: 500), (t) {
              final w = _renderer.videoWidth;
              final h = _renderer.videoHeight;
              if (w > 0 && h > 0) {
                t.cancel();
                debugPrint('[WebRTC] Video dimensions: ${w}x${h} ratio=${w/h}');
                if (mounted) setState(() => _videoSize = Size(w.toDouble(), h.toDouble()));
              }
            });
          }
        }
      };

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(jsep['sdp'], jsep['type']),
      );

      final answer = await _peerConnection!.createAnswer({});
      await _peerConnection!.setLocalDescription(answer);

      final started = await widget.didService.startStream(
        streamId: streamId!,
        sessionId: sessionId!,
        answer: {'type': answer.type, 'sdp': answer.sdp},
      );
      debugPrint('[WebRTC] startStream result: $started');

      if (!started && mounted) {
        setState(() => _status = 'Failed to start ICE exchange');
      }

    } catch (e) {
      debugPrint('[WebRTC] Exception: $e');
      final detail = widget.didService.lastError;
      if (mounted) {
        setState(() => _status = detail != null ? 'Error: $detail' : 'Error connecting — check debug console');
      }
    }
  }

  Future<void> speak(String text, {String? audioUrl}) async {
    if (streamId != null && sessionId != null) {
      await widget.didService.sendTask(
        streamId: streamId!,
        sessionId: sessionId!,
        text: text,
        voiceProvider: widget.voiceProvider,
        voiceId: widget.voiceId,
        audioUrl: audioUrl,
      );
    }
  }

  @override
  void dispose() {
    _dimensionPoller?.cancel();
    final sId = streamId;
    final sessId = sessionId;
    if (sId != null && sessId != null) {
      widget.didService.deleteStream(streamId: sId, sessionId: sessId);
    }
    _peerConnection?.close();
    if (_initialized) {
      _renderer.dispose();
    }
    super.dispose();
  }

  bool get _isError =>
      _status.startsWith('Error') ||
      _status.startsWith('D-ID Session Failed') ||
      _status.startsWith('Invalid') ||
      _status.startsWith('Failed');

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return ColoredBox(
        color: Colors.black.withValues(alpha: widget.fillScreen ? 1.0 : 0.35),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (_isError) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _status));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14, color: Colors.white38),
                    label: const Text(
                      'Copy error',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (widget.fillScreen) {
      // D-ID outputs 512×512 square. Use Cover to fill the portrait screen,
      // aligned to the top so the face appears in the same position as the
      // static preview photo (which also uses BoxFit.cover + center alignment).
      return SizedBox.expand(
        child: RTCVideoView(
          _renderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      );
    }

    final inner = ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: RTCVideoView(
        _renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: AspectRatio(
        aspectRatio: 1,
        child: inner,
      ),
    );
  }
}
