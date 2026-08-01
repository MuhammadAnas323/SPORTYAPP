import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/video_url.dart';

/// Responsive live video player for HLS (`.m3u8`), MP4 (`.mp4`) and DASH
/// (`.mpd`) streams.
///
/// Auto-plays and loops the stream (live), offers fullscreen/mute controls and
/// keeps the 16:9 stream responsive to the available width. If the URL is
/// missing, not a supported format, or fails to initialize, it renders
/// [SizedBox.shrink] so callers can fall back to the regular data card.
class MatchVideoPlayer extends StatefulWidget {
  const MatchVideoPlayer({
    super.key,
    required this.videoUrl,
    this.borderRadius,
    this.autoPlay = true,
  });

  /// Live stream URL (`.m3u8`, `.mp4`, `.mpd`). Null hides the player.
  final String? videoUrl;

  /// Corner radius applied to the player frame.
  final double? borderRadius;

  /// Whether playback starts automatically (live streams should).
  final bool autoPlay;

  @override
  State<MatchVideoPlayer> createState() => _MatchVideoPlayerState();
}

class _MatchVideoPlayerState extends State<MatchVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!MatchVideoUrl.isPlayable(widget.videoUrl)) {
      _failed = true;
    } else {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      final aspectRatio =
          controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9;

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        aspectRatio: aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: primaryColor,
          handleColor: primaryColor,
        ),
      );

      setState(() {
        _controller = controller;
        _chewieController = chewie;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewieController;
    if (_failed || chewie == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(widget.borderRadius ?? AppSizes.radiusCard),
      child: AspectRatio(
        aspectRatio: chewie.aspectRatio ?? 16 / 9,
        child: Chewie(controller: chewie),
      ),
    );
  }
}
