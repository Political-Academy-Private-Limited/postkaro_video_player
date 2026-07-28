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

class _AnimationWidgetState extends State<AnimationWidget> {
  late Alignment _alignment;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _resetAndStart();
  }

  @override
  void didUpdateWidget(covariant AnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationType != widget.animationType) {
      _resetAndStart();
    }
  }

  Alignment _toAlignment(Offset offset) {
    return Alignment(
      offset.dx * 2 - 1,
      offset.dy * 2 - 1,
    );
  }

  Future<void> _resetAndStart() async {
    _alignment = _toAlignment(widget.animationType.startOffset);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _alignment = _toAlignment(widget.animationType.endOffset);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    return AnimatedAlign(
      duration: widget.animationType.duration,
      curve: Curves.easeInOut,
      alignment: _alignment,
      child: widget.animatedOverlay,
    );
  }
}
