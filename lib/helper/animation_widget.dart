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

  @override
  void initState() {
    super.initState();

    _alignment = Alignment(
      widget.animationType.startOffset.dx * 2 - 1,
      widget.animationType.startOffset.dy * 2 - 1,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _alignment = Alignment(
          widget.animationType.endOffset.dx * 2 - 1,
          widget.animationType.endOffset.dy * 2 - 1,
        );
      });
    });
  }

  @override
  void didUpdateWidget(covariant AnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationType != widget.animationType) {
      setState(() {
        _alignment = Alignment(
          widget.animationType.startOffset.dx * 2 - 1,
          widget.animationType.startOffset.dy * 2 - 1,
        );
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _alignment = Alignment(
            widget.animationType.endOffset.dx * 2 - 1,
            widget.animationType.endOffset.dy * 2 - 1,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: widget.animationType.duration,
      curve: Curves.easeInOut,
      alignment: _alignment,
      child: widget.animatedOverlay,
    );
  }
}
