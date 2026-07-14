import 'dart:ui';

enum OverlayAnimationType {
  none,
  topCenter,

  // Basic
  topToCenter,
  rightToCenter,
  leftToCenter,
  bottomToCenter,
  leftToRight,
  rightToLeft,

  // Diagonal
  diagonalTopLeftToBottomRight,
  diagonalTopRightToBottomLeft,
  diagonalBottomLeftToTopRight,
  diagonalBottomRightToTopLeft,
}

///this are types of start/end position
enum OverlayPosition {
  topLeft,
  topCenter,
  topRight,

  centerLeft,
  center,
  centerRight,

  bottomLeft,
  bottomCenter,
  bottomRight,
}

class OverlayAnimation {
  final Offset start;
  final Offset end;
  final Duration duration;

  const OverlayAnimation({
    required this.start,
    required this.end,
    required this.duration,
  });
}
