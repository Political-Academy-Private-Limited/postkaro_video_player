import 'package:flutter/material.dart';
import 'overlay_animation_type.dart';

class AnimationWidget extends StatefulWidget {
  final OverlayAnimationData animationType;
  final Widget animatedOverlay;

  const AnimationWidget({
    super.key,
    required this.animationType,
    required this.animatedOverlay,
  });

  @override
  State<AnimationWidget> createState() => _AnimationWidgetState();
}

class _AnimationWidgetState extends State<AnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;

  bool _visible = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationType.duration,
    );

    _configureAnimation();
    _resetAndStart();
  }

  @override
  void didUpdateWidget(covariant AnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationType != widget.animationType) {
      _controller.duration = widget.animationType.duration;
      _configureAnimation();
      _resetAndStart();
    }
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
