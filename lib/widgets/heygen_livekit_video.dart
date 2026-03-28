import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// Subscribes to HeyGen's LiveKit room (receive-only; avatar video from remote participant).
class HeyGenLiveKitVideo extends StatefulWidget {
  const HeyGenLiveKitVideo({
    super.key,
    required this.url,
    required this.token,
    /// Full-bleed cover (live session). When false, small circular preview.
    this.fillScreen = false,
  });

  final String url;
  final String token;
  final bool fillScreen;

  @override
  State<HeyGenLiveKitVideo> createState() => _HeyGenLiveKitVideoState();
}

class _HeyGenLiveKitVideoState extends State<HeyGenLiveKitVideo> {
  Room? _room;
  VideoTrack? _videoTrack;
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = 'Connecting…';
    _connect();
  }

  Future<void> _connect() async {
    final room = Room();
    room.addListener(_syncVideo);
    try {
      await room.connect(widget.url, widget.token);
      if (!mounted) {
        await _tearDown(room);
        return;
      }
      setState(() {
        _room = room;
        _status = 'Waiting for avatar video…';
      });
      _syncVideo();
    } catch (e, st) {
      debugPrint('HeyGen LiveKit connect failed: $e\n$st');
      if (mounted) {
        setState(() {
          _status = 'Video unavailable';
        });
      }
      await _tearDown(room);
    }
  }

  void _syncVideo() {
    final track = _firstRemoteCameraTrack(_room);
    if (!mounted) return;
    setState(() {
      _videoTrack = track;
      if (track != null) {
        _status = null;
      }
    });
  }

  VideoTrack? _firstRemoteCameraTrack(Room? room) {
    if (room == null) return null;
    for (final p in room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        if (pub.isScreenShare) continue;
        final t = pub.track;
        if (pub.subscribed && t is VideoTrack) {
          return t;
        }
      }
    }
    return null;
  }

  Future<void> _tearDown(Room room) async {
    room.removeListener(_syncVideo);
    try {
      await room.disconnect();
    } catch (_) {}
    try {
      await room.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    final r = _room;
    if (r != null) {
      unawaited(_tearDown(r));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _videoTrack;
    final inner = ColoredBox(
      color: Colors.black.withValues(alpha: widget.fillScreen ? 1.0 : 0.35),
      child: track != null
          ? VideoTrackRenderer(
              track,
              fit: VideoViewFit.cover,
              renderMode: VideoRenderMode.texture,
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _status ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
    );
    if (widget.fillScreen) {
      return SizedBox.expand(child: inner);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: AspectRatio(
        aspectRatio: 1,
        child: inner,
      ),
    );
  }
}
