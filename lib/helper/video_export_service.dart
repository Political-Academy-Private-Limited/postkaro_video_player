import 'package:flutter/material.dart';
import 'package:houseoftech_video_player/helper/utils.dart';

import 'overlay_animation_type.dart';

Future<String?> exportVideoWithOverlay({
  bool downloadWithOverlay = false,
  required String videoUrl,
  GlobalKey? bottomOverlayKey,
  GlobalKey? topOverlayKey,
  GlobalKey? animatedOverlayKey,
  GlobalKey? overlayKey,
  Offset? overlayOffSet,
  GlobalKey? overlayKey1,
  Offset? overlayOffSet1,
  required OverlayAnimationData animationType,
  String? ttsText,
  void Function(double progress)? onProgress,
}) async {
  try {
    final videoPath = await downloadVideo(videoUrl);

    if (videoPath == null) {
      return null;
    }

    if (!downloadWithOverlay) {
      return videoPath;
    }

    String? overlayPath;
    if (bottomOverlayKey != null) {
      overlayPath = await captureOverlay(bottomOverlayKey, "bottomOverlay");
    }

    String? audioFilePath;
    if (ttsText != null && ttsText.trim().isNotEmpty) {
      audioFilePath = await convertTextToSpeech(ttsText);
    }

    final results = await Future.wait<String?>([
      topOverlayKey != null
          ? captureOverlay(topOverlayKey, "topOverlay")
          : Future.value(null),
      animatedOverlayKey != null
          ? captureOverlay(animatedOverlayKey, "animatedOverlay")
          : Future.value(null),
      overlayKey != null
          ? captureOverlay(overlayKey, "overlayKey")
          : Future.value(null),
      overlayKey1 != null
          ? captureOverlay(overlayKey1, "overlayKey1")
          : Future.value(null),
    ]);

    final topOverlayPath = results[0];
    final animatedOverlayPath = results[1];
    final overlayWidgetPath = results[2];
    final overlayWidgetPath1 = results[3];

    final finalVideo = await mergeVideoWithOverlay(
      videoPath,
      overlayPath,
      topOverlayPath: topOverlayPath,
      animatedOverlayPath: animatedOverlayPath,
      overlayWidgetOffSet: overlayOffSet,
      overlayWidgetPath: overlayWidgetPath,
      overlayWidgetOffSet1: overlayOffSet1,
      overlayWidgetPath1: overlayWidgetPath1,
      animationData: animationType,
      audioFilePath: audioFilePath,
      onProgress: onProgress,
    );

    return finalVideo;
  } catch (e) {
    return null;
  }
}
