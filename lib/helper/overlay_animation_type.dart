import 'dart:ui';

class OverlayAnimationData {
  final Offset startOffset;
  final Offset endOffset;

  /// duration will always be milliseconds.
  /// if you need 5 sec of animation from start to end
  /// use milliseconds: 5000 not seconds: 5
  final Duration duration;

  final Duration startDuration;

  const OverlayAnimationData({
    required this.startOffset,
    required this.endOffset,
    required this.duration,
    required this.startDuration,
  });

  OverlayAnimationData copyWith({
    Offset? startOffset,
    Offset? endOffset,
    Duration? duration,
    Duration? startDuration,
  }) {
    return OverlayAnimationData(
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      duration: duration ?? this.duration,
      startDuration: startDuration ?? this.startDuration,
    );
  }

  /// Pushes [startOffset] fully outside the frame using [animSize] (0–1).
  OverlayAnimationData withOutsideStart(Size? animSize) {
    if (animSize == null) return this;

    double x = startOffset.dx;
    double y = startOffset.dy;

    if (x <= 0) {
      x = x - animSize.width;
    } else if (x >= 1) {
      x = x + animSize.width;
    }

    if (y <= 0) {
      y = y - animSize.height;
    } else if (y >= 1) {
      y = y + animSize.height;
    }

    return copyWith(startOffset: Offset(x, y));
  }
}
