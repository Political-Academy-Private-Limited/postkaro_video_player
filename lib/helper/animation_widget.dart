import 'package:flutter/material.dart';

import 'overlay_animation_type.dart';

class AnimationWidget extends StatefulWidget {
  final OverlayAnimationType animationType;
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
  late Alignment _startAlignment;
  late Alignment _endAlignment;
  late Alignment _currentAlignment;

  @override
  void initState() {
    super.initState();

    _configureAnimation(widget.animationType);

    _currentAlignment = _startAlignment;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _currentAlignment = _endAlignment;
      });
    });
  }

  void _configureAnimation(OverlayAnimationType type) {
    switch (type) {
      // ======================
      // NONE
      // ======================
      case OverlayAnimationType.none:
        _startAlignment = Alignment.center;
        _endAlignment = Alignment.center;
        break;

      // ======================
      // BASIC TO CENTER
      // ======================
      case OverlayAnimationType.topToCenter:
        _startAlignment = Alignment.topCenter;
        _endAlignment = Alignment.center;
        break;

      case OverlayAnimationType.bottomToCenter:
        _startAlignment = Alignment.bottomCenter;
        _endAlignment = Alignment.center;
        break;

      case OverlayAnimationType.leftToCenter:
        _startAlignment = Alignment.centerLeft;
        _endAlignment = Alignment.center;
        break;

      case OverlayAnimationType.rightToCenter:
        _startAlignment = Alignment.centerRight;
        _endAlignment = Alignment.center;
        break;

      case OverlayAnimationType.leftToRight:
        _startAlignment = Alignment.centerLeft;
        _endAlignment = Alignment.centerRight;
        break;

      case OverlayAnimationType.rightToLeft:
        _startAlignment = Alignment.centerRight;
        _endAlignment = Alignment.centerLeft;
        break;

      // ======================
      // DIAGONAL
      // ======================
      case OverlayAnimationType.diagonalTopLeftToBottomRight:
        _startAlignment = Alignment.topLeft;
        _endAlignment = Alignment.bottomRight;
        break;

      case OverlayAnimationType.diagonalTopRightToBottomLeft:
        _startAlignment = Alignment.topRight;
        _endAlignment = Alignment.bottomLeft;
        break;

      case OverlayAnimationType.diagonalBottomLeftToTopRight:
        _startAlignment = Alignment.bottomLeft;
        _endAlignment = Alignment.topRight;
        break;

      case OverlayAnimationType.diagonalBottomRightToTopLeft:
        _startAlignment = Alignment.bottomRight;
        _endAlignment = Alignment.topLeft;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      alignment: _currentAlignment,
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      child: widget.animatedOverlay,
    );
  }
}
