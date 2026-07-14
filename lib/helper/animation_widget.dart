import 'package:flutter/material.dart';
import 'overlay_animation_type.dart';

class AnimationWidget extends StatefulWidget {
  final OverlayAnimationData animationType;
  final Widget animatedOverlay;
  final double width;
  final double height;

  const AnimationWidget({
    super.key,
    required this.animationType,
    required this.animatedOverlay,
    required this.width,
    required this.height,
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
      widget.animationType.start.dx * 2 - 1,
      widget.animationType.start.dy * 2 - 1,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _alignment = Alignment(
          widget.animationType.end.dx * 2 - 1,
          widget.animationType.end.dy * 2 - 1,
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
          widget.animationType.start.dx * 2 - 1,
          widget.animationType.start.dy * 2 - 1,
        );
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _alignment = Alignment(
            widget.animationType.end.dx * 2 - 1,
            widget.animationType.end.dy * 2 - 1,
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
