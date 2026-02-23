import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';

import '../jar_video_player.dart';

// import '../jar_video_player.dart';

/// A customizable video player widget for playing network videos.
///
/// Supports reels-style auto play/pause, looping, and manual control.
///
/// Requires a [JarVideoPlayerController] to control playback.

class JarVideoPlayer extends StatefulWidget {
  /// This is for pausing and playing the video if routes changes!!!
  final VideoRouteObserver? videoRouteObserver;

  /// Network video URL to play.
  final String url;

  /// Controller used to control playback (play, pause, etc).
  final JarVideoPlayerController? controller;

  /// Whether video should auto play when initialized.
  ///
  /// Defaults to false.
  final bool autoPlay;

  /// custom aspect ratio.
  /// default value is 9/16
  final double? aspectRatio;

  /// Whether the video should loop after completion.
  ///
  /// Defaults to false.
  final bool loop;

  /// Enables reels-style behavior.
  ///
  /// When true, video auto plays and pauses based on visibility.
  final bool reelsMode;

  /// Creates a [JarVideoPlayer].
  ///
  /// The [url] parameter is required and must be a valid network video URL.
  ///
  /// The [controller] is optional to control playback.
  ///
  /// If [reelsMode] is true, the video automatically plays
  /// when visible and pauses when not visible.

  /// for now only isLoading is working, progress wil be implemented in future
  final void Function(bool isLoading, double progress)? onStatusChanged;

  ///

  const JarVideoPlayer({
    super.key,
    this.controller,
    required this.url,
    this.autoPlay = false,
    this.loop = false,
    this.reelsMode = false,
    this.aspectRatio,
    this.onStatusChanged,
    this.videoRouteObserver,
  });
  @override
  State<JarVideoPlayer> createState() => _JarVideoPlayerState();
}

class _JarVideoPlayerState extends State<JarVideoPlayer>
    with WidgetsBindingObserver, RouteAware {
  late final JarVideoPlayerController _controller;

  bool _disposed = false;
  int _initToken = 0;
  bool _loading = true;
  bool _isVisible = false;
  bool _overlayActive = false;
  bool _isActuallyPlaying = false;
  late VoidCallback _openListener;
  late VoidCallback _closeListener;
  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = widget.controller ?? JarVideoPlayerController();
    if (widget.videoRouteObserver != null) {
      _openListener = () {
        _overlayActive = true;
        _safePause();
      };

      _closeListener = () {
        _overlayActive = false;
        if (widget.autoPlay || widget.reelsMode) {
          _safePlay();
        }
      };

      widget.videoRouteObserver!.addListener(
        onOpen: _openListener,
        onClose: _closeListener,
      );
    }

    _init();
  }

  Future<void> _init() async {
    if (_controller.isInitialized) return;
    final currentToken = ++_initToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStatusChanged?.call(true, 1.0);
    });
    try {
      /// Download & cache video first
      final File file = await DefaultCacheManager().getSingleFile(widget.url);

      /// Pass local file path instead of network URL
      await _controller.initialize(
        file.path,
        loop: widget.reelsMode ? true : widget.loop,
      );

      /// If widget was disposed or another init started, ignore
      if (!mounted || _disposed || currentToken != _initToken) {
        await _controller.disposeVideo();
        return;
      }

      if (!_overlayActive) {
        if (widget.reelsMode) {
          if (_isVisible) {
            _safePlay();
          }
        } else if (widget.autoPlay) {
          _safePlay();
        }
      }

      setState(() {
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onStatusChanged?.call(false, 1.0);
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onStatusChanged?.call(false, 1.0);
      });
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (widget.videoRouteObserver != null) {
      widget.videoRouteObserver!.removeListener(
        onOpen: _openListener,
        onClose: _closeListener,
      );
    }
    _controller.pause();

    ///  stop audio immediately
    _controller.disposeVideo();

    /// free decoder

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    _safePause();
  }

  @override
  void didPopNext() {
    if (widget.autoPlay || widget.reelsMode) {
      _safePlay();
    }
  }

  /// ---------------------------
  ///App Lifecycle
  ///---------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.isInitialized) return;

    ///automatically pause when the screen is not in focus or is not visible
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _safePause();
    }

    ///automatically play the video if it comes back to focus or is visible.

    else if (state == AppLifecycleState.resumed) {
      if (widget.autoPlay || widget.reelsMode) {
        _safePlay();
      }
    }
  }

  ///---------------------------
  ///Visibility (Reels Mode)
  ///---------------------------

  Future<void> _handleVisibility(double visibleFraction) async {
    if (!widget.reelsMode || _disposed || _overlayActive) return;

    final isNowVisible = visibleFraction > 0.6;

    if (isNowVisible == _isVisible) return;

    _isVisible = isNowVisible;

    if (_isVisible) {
      if (!_controller.isInitialized) {
        await _init();
      } else {
        _safePlay(); // use safe version
      }
    } else {
      _safePause(); // use safe version
    }
  }

  ///---------------------------
  ///Safe Play / Pause
  ///---------------------------

  void _safePlay() {
    if (_overlayActive) return;
    if (!_controller.isInitialized) return;
    log("before play 275");

    _controller.play();
    log("after play 275");
    _isActuallyPlaying = true;
  }

  void _safePause() async {
    if (!_controller.isInitialized) return;
    log("before pause 282");

    _controller.pause();

    _isActuallyPlaying = false;
  }

  //
  void _togglePlayPause() {
    if (!_controller.isInitialized) return;

    if (_isActuallyPlaying) {
      _safePause();
    } else {
      _safePlay();
    }
    setState(() {});
  }

  ///---------------------------
  ///UI
  ///---------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading || !_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final vc = _controller.videoController;

    Widget video;

    if (widget.reelsMode) {
      video = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: vc!.value.size.width,
            height: vc.value.size.height,
            child: VideoPlayer(vc),
          ),
        ),
      );
    } else {
      // 🎥 Normal Aspect Ratio Mode
      video = AspectRatio(
        aspectRatio: widget.aspectRatio ?? vc!.value.aspectRatio,
        child: VideoPlayer(vc!),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        widget.reelsMode
            ? VisibilityDetector(
                key: ValueKey(widget.url),
                onVisibilityChanged: (info) {
                  _handleVisibility(info.visibleFraction);
                },
                child: video,
              )
            : video,
        if (!widget.reelsMode)
          GestureDetector(
            onTap: _togglePlayPause,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _controller.isPlaying ? 0 : 1,
              child: const Icon(
                Icons.play_circle_fill,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
