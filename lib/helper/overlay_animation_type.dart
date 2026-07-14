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

class OverlayAnimationData {
  final Offset startOffset;
  final Offset endOffset;

  ///duration will always be milliseconds.
  ///if you need 5 sec of animation from start to end
  ///use milliseconds: 5000 not seconds: 5
  final Duration duration;

  const OverlayAnimationData({
    required this.startOffset,
    required this.endOffset,
    required this.duration,
  });
}
