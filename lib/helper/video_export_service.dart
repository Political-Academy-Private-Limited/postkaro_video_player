import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:houseoftech_video_player/helper/utils.dart';

import 'overlay_animation_type.dart';

Future<String?> exportVideoWithOverlay({
  bool downloadWithOverlay = false,
  required String videoUrl,
  GlobalKey? playerKey,
  GlobalKey? bottomOverlayKey,
  GlobalKey? topOverlayKey,
  GlobalKey? animatedOverlayKey,
  GlobalKey? overlayKey,
  Offset? overlayOffSet,
  GlobalKey? overlayKey1,
  Offset? overlayOffSet1,
  required OverlayAnimationData animationType,
  Size? animSize,
  String? ttsText,
  void Function(double progress)? onProgress,
}) async {
  try {
    if (!downloadWithOverlay) {
      return await downloadVideo(videoUrl);
    }

    final playerSize = playerKey != null ? readWidgetSize(playerKey) : null;

    final downloadFuture = downloadVideo(videoUrl);
    final ttsFuture = (ttsText != null && ttsText.trim().isNotEmpty)
        ? convertTextToSpeech(ttsText)
        : Future<String?>.value(null);

    final videoPath = await downloadFuture;
    if (videoPath == null) return null;

    final info = await getVideoInfo(videoPath);
    if (info == null) return null;

    // Supersample ~2x video density for sharp lanczos downscale
    final mediaDpr = playerKey?.currentContext != null
        ? MediaQuery.maybeOf(playerKey!.currentContext!)?.devicePixelRatio ?? 2.0
        : 2.0;
    final videoRatio = (playerSize != null && playerSize.width > 0)
        ? info.width / playerSize.width
        : mediaDpr;
    final captureRatio =
        math.max(videoRatio * 2.0, mediaDpr * 2.0).clamp(2.0, 6.0);

    final capturesFuture = Future.wait<CapturedOverlay?>([
      bottomOverlayKey != null
          ? captureOverlay(
              bottomOverlayKey, "bottomOverlay",
              pixelRatio: captureRatio)
          : Future.value(null),
      topOverlayKey != null
          ? captureOverlay(
              topOverlayKey, "topOverlay",
              pixelRatio: captureRatio)
          : Future.value(null),
      animatedOverlayKey != null
          ? captureOverlay(
              animatedOverlayKey, "animatedOverlay",
              pixelRatio: captureRatio)
          : Future.value(null),
      overlayKey != null
          ? captureOverlay(
              overlayKey, "overlayKey",
              pixelRatio: captureRatio)
          : Future.value(null),
      overlayKey1 != null
          ? captureOverlay(
              overlayKey1, "overlayKey1",
              pixelRatio: captureRatio)
          : Future.value(null),
    ]);

    final results = await Future.wait([ttsFuture, capturesFuture]);
    final audioFilePath = results[0] as String?;
    final captures = results[1] as List<CapturedOverlay?>;

    return mergeVideoWithOverlay(
      videoPath,
      captures[0],
      topOverlay: captures[1],
      animatedOverlay: captures[2],
      overlayWidget: captures[3],
      overlayWidgetOffSet: overlayOffSet,
      overlayWidget1: captures[4],
      overlayWidgetOffSet1: overlayOffSet1,
      animationData: animationType,
      animSize: animSize,
      playerLogicalSize: playerSize,
      audioFilePath: audioFilePath,
      onProgress: onProgress,
      videoWidth: info.width,
      videoHeight: info.height,
      videoDuration: info.duration,
      videoFps: info.fps,
    );
  } catch (e, st) {
    debugPrint("Export error: $e\n$st");
    return null;
  }
}
