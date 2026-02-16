import 'package:flutter/material.dart';
import 'package:jar_video_player/src/utils.dart';

Future<String?> exportVideoWithOverlay({
  required String videoUrl,
  required GlobalKey overlayKey,
}) async {
  try {
    /// 1️⃣ Download original video
    final videoPath = await downloadVideo(videoUrl);

    /// 2️⃣ Capture overlay as image
    final overlayPath = await captureOverlay(overlayKey);

    /// 3️⃣ Merge with FFmpeg
    if(videoPath != null) {
      final finalVideo = await mergeVideoWithOverlay(videoPath, overlayPath);
      return finalVideo;
    }


  } catch (e) {
    debugPrint("Export error: $e");
    return null;
  }
}
