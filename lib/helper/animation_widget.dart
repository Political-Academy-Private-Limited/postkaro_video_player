import 'package:flutter/material.dart';
import 'overlay_animation_type.dart';

class AnimationWidget extends StatefulWidget {
  final OverlayAnimation animationType;
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
  late Alignment _currentAlignment;

  Alignment _getAlignment(OverlayPosition position) {
    switch (position) {
      case OverlayPosition.topLeft:
        return Alignment.topLeft;
      case OverlayPosition.topCenter:
        return Alignment.topCenter;
      case OverlayPosition.topRight:
        return Alignment.topRight;

      case OverlayPosition.centerLeft:
        return Alignment.centerLeft;
      case OverlayPosition.center:
        return Alignment.center;
      case OverlayPosition.centerRight:
        return Alignment.centerRight;

      case OverlayPosition.bottomLeft:
        return Alignment.bottomLeft;
      case OverlayPosition.bottomCenter:
        return Alignment.bottomCenter;
      case OverlayPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  @override
  void initState() {
    super.initState();

    _currentAlignment = _getAlignment(widget.animationType.start);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _currentAlignment = _getAlignment(widget.animationType.end);
      });
    });
  }

  @override
  void didUpdateWidget(covariant AnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationType != widget.animationType) {
      _currentAlignment = _getAlignment(widget.animationType.start);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _currentAlignment = _getAlignment(widget.animationType.end);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      alignment: _currentAlignment,
      duration: widget.animationType.duration,
      curve: Curves.easeIn,
      child: widget.animatedOverlay,
    );
  }
}