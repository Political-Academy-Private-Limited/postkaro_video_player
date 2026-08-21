import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../houseoftech_video_player.dart';

class AnimationWidget extends StatefulWidget {
  final OverlayAnimationData animationType;
  final Widget animatedOverlay;
  final HouseOfTechController? controller;

  const AnimationWidget({
    super.key,
    required this.animationType,
    required this.animatedOverlay,
    this.controller,
  });

  @override
  State<AnimationWidget> createState() => _AnimationWidgetState();
}

class _AnimationWidgetState extends State<AnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;

  bool _visible = false;
  Duration _lastPosition = Duration.zero;
  VideoPlayerController? _lastVideoPlayerController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationType.duration,
    );

    _configureAnimation();

    if (widget.controller != null) {
      widget.controller!.addListener(_onControllerChanged);
      _onControllerChanged();
    } else {
      _resetAndStart();
    }
  }

  @override
  void didUpdateWidget(covariant AnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationType != widget.animationType) {
      _controller.duration = widget.animationType.duration;
      _configureAnimation();
      if (widget.controller == null) {
        _resetAndStart();
      }
    }

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      _removeVideoListener();

      widget.controller?.addListener(_onControllerChanged);
      _onControllerChanged();
    }
  }

  void _removeVideoListener() {
    _lastVideoPlayerController?.removeListener(_onVideoControllerChanged);
    _lastVideoPlayerController = null;
  }

  void _onControllerChanged() {
    final videoPlayerController = widget.controller?.videoController;
    if (videoPlayerController != _lastVideoPlayerController) {
      _removeVideoListener();
      _lastVideoPlayerController = videoPlayerController;
      _lastVideoPlayerController?.addListener(_onVideoControllerChanged);
      _onVideoControllerChanged();
    }
  }

  void _onVideoControllerChanged() {
    final videoPlayerController = _lastVideoPlayerController;
    if (videoPlayerController == null ||
        !videoPlayerController.value.isInitialized) {
      return;
    }

    final currentPosition = videoPlayerController.value.position;
    final isPlaying = videoPlayerController.value.isPlaying;

    // Sync visibility based on startDuration
    final shouldBeVisible =
        currentPosition >= widget.animationType.startDuration;
    if (shouldBeVisible != _visible) {
      if (mounted) {
        setState(() {
          _visible = shouldBeVisible;
        });
      }
    }

    // Sync Play/Pause and Loop
    if (isPlaying) {
      final animationElapsed =
          currentPosition - widget.animationType.startDuration;

      if (animationElapsed >= Duration.zero &&
          animationElapsed < widget.animationType.duration) {
        // We are within the animation timeframe
        final progress = animationElapsed.inMilliseconds /
            widget.animationType.duration.inMilliseconds;

        // If the video just looped or seeked back, currentPosition < _lastPosition
        // or if we are just starting to play
        if (!_controller.isAnimating || (currentPosition < _lastPosition)) {
          _controller.forward(from: progress);
        }
      } else if (animationElapsed >= widget.animationType.duration) {
        // Animation finished
        if (_controller.value != 1.0) {
          _controller.value = 1.0;
        }
      } else {
        // Before animation starts
        if (_controller.value != 0.0) {
          _controller.reset();
        }
      }
    } else {
      // Video is paused
      if (_controller.isAnimating) {
        _controller.stop();
      }

      // Sync progress while paused (for seeking)
      final animationElapsed =
          currentPosition - widget.animationType.startDuration;
      if (animationElapsed >= Duration.zero &&
          animationElapsed < widget.animationType.duration) {
        final progress = animationElapsed.inMilliseconds /
            widget.animationType.duration.inMilliseconds;
        _controller.value = progress;
      } else if (animationElapsed >= widget.animationType.duration) {
        _controller.value = 1.0;
      } else {
        _controller.value = 0.0;
      }
    }

    _lastPosition = currentPosition;
  }

  Alignment _toAlignment(Offset offset) {
    return Alignment(
      offset.dx * 2 - 1,
      offset.dy * 2 - 1,
    );
  }

  void _configureAnimation() {
    _alignmentAnimation = AlignmentTween(
      begin: _toAlignment(widget.animationType.startOffset),
      end: _toAlignment(widget.animationType.endOffset),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _resetAndStart() async {
    _controller.reset();

    if (mounted) {
      setState(() {
        _visible = false;
      });
    }

    if (widget.animationType.startDuration > Duration.zero) {
      await Future.delayed(widget.animationType.startDuration);
    }

    if (!mounted) return;

    setState(() {
      _visible = true;
    });

    _controller.forward();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    widget.controller?.videoController
        ?.removeListener(_onVideoControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _alignmentAnimation,
      builder: (context, child) {
        return Align(
          alignment: _alignmentAnimation.value,
          child: child,
        );
      },
      child: widget.animatedOverlay,
    );
  }
}
