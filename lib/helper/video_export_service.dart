import 'package:flutter/material.dart';
import 'package:houseoftech_video_player/helper/utils.dart';

import 'overlay_animation_type.dart';

Future<String?> exportVideoWithOverlay({
  bool downloadWithOverlay = false,
  required String videoUrl,
  required GlobalKey bottomOverlayKey,
  GlobalKey? topOverlayKey,
  GlobalKey? animatedOverlayKey,
  required OverlayAnimationData animationType,
  String? ttsText,
}) async {
  try {
    final videoPath = await downloadVideo(videoUrl);

    if (videoPath == null) {
      return null;
    }

    if (!downloadWithOverlay) {
      return videoPath;
    }

    final overlayPath = await captureOverlay(bottomOverlayKey, "bottomOverlay");

    if (overlayPath == null) {
      return null;
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
    ]);

    final topOverlayPath = results[0];
    final animatedOverlayPath = results[1];

    final finalVideo = await mergeVideoWithOverlay(
      videoPath,
      overlayPath,
      topOverlayPath: topOverlayPath,
      animatedOverlayPath: animatedOverlayPath,
      animationData: animationType,
      audioFilePath: audioFilePath,
    );

    return finalVideo;
  } catch (e) {
    return null;
  }
}
