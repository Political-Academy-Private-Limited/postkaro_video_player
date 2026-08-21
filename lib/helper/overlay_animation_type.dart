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
}
