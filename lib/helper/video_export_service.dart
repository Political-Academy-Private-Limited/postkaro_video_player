import 'package:flutter/material.dart';
import 'package:jar_video_player/helper/utils.dart';

import 'overlay_animation_type.dart';

Future<String?> exportVideoWithOverlay(
    {bool downloadWithOverlay = false,
    required String videoUrl,
    required GlobalKey bottomOverlayKey,
    GlobalKey? topOverlayKey,
    GlobalKey? animatedOverlayKey,
    OverlayAnimationType? animationType}) async {
  try {
    /// 1️⃣ Download original video
    final videoPath = await downloadVideo(videoUrl);

    if (!downloadWithOverlay) {
      return videoPath;
    }

    /// 2️⃣ Capture overlay as image
    final overlayPath = await captureOverlay(bottomOverlayKey, "bottomOverlay");

    String? animatedOverlayPath;

    if (animatedOverlayKey != null) {
      animatedOverlayPath =
          await captureOverlay(animatedOverlayKey, "animatedOverlay");
    }

    if (topOverlayKey != null) {
      final topOverPath = await captureOverlay(topOverlayKey, "topOverlay");

      /// 3️⃣ Merge with FFmpeg both top and bottom overlay
      if (videoPath != null) {
        final finalVideo = await mergeVideoWithOverlay(videoPath, overlayPath!,
            topOverlayPath: topOverPath,
            animatedOverlayPath: animatedOverlayPath,
            animationType: animationType ?? OverlayAnimationType.topToCenter);
        return finalVideo;
      }
    } else {
      /// 3️⃣ Merge with FFmpeg
      if (videoPath != null) {
        final finalVideo = await mergeVideoWithOverlay(videoPath, overlayPath!,
            animatedOverlayPath: animatedOverlayPath,
            animationType: animationType ?? OverlayAnimationType.topToCenter);
        return finalVideo;
      }
    }
  } catch (e) {
    return null;
  }
  return null;
}
