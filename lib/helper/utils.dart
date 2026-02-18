import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'overlay_animation_type.dart';

/// ===============================
/// CAPTURE OVERLAY (High Quality)
/// ===============================
Future<String?> captureOverlay(GlobalKey key, String fileName) async {
  try {
    if (key.currentContext == null) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (key.currentContext == null) return null;
    }

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null || boundary.size.isEmpty) return null;

    final pixelRatio = MediaQuery.of(key.currentContext!).devicePixelRatio * 2;

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    final Directory tempDir = await getTemporaryDirectory();
    final File imageFile = File('${tempDir.path}/${fileName}_overlay.png');

    await imageFile.writeAsBytes(pngBytes);

    return imageFile.path;
  } catch (e) {
    rethrow;
  }
}

/// ===============================
/// DOWNLOAD VIDEO
/// ===============================
Future<String?> downloadVideo(String videoUrl) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final videoFileName = videoUrl.split('/').last.split('?').first;

    final videoFile = File('${tempDir.path}/$videoFileName');

    final response = await http.get(Uri.parse(videoUrl));

    if (response.statusCode == 200) {
      await videoFile.writeAsBytes(response.bodyBytes);
      return videoFile.path;
    } else {
      return null;
    }
  } catch (e) {
    rethrow;
  }
}

/// ===============================
/// GET VIDEO RESOLUTION (FFprobe)
/// ===============================
Future<Map<String, int>?> getVideoResolution(String path) async {
  try {
    final session = await FFprobeKit.execute(
      '-v error -select_streams v:0 '
      '-show_entries stream=width,height '
      '-of csv=p=0:s=x "$path"',
    );

    final output = await session.getOutput();

    if (output == null || output.trim().isEmpty) return null;

    final parts = output.trim().split("x");
    if (parts.length != 2) return null;

    return {
      "width": int.parse(parts[0]),
      "height": int.parse(parts[1]),
    };
  } catch (_) {
    rethrow;
  }
}

/// ===============================
/// MERGE VIDEO + OVERLAY (Optimal)
/// ===============================

// Future<String?> mergeVideoWithOverlay(
//   String videoPath,
//   String bottomOverlayPath, {
//   String? topOverlayPath,
// }) async {
//   try {
//     final dir = await getTemporaryDirectory();
//     final outputPath =
//         "${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.mp4";
//
//     final resolution = await getVideoResolution(videoPath);
//
//     if (resolution == null) {
//       log("Could not detect video resolution");
//       return null;
//     }
//
//     final int videoWidth = resolution['width']!;
//     // final int videoHeight = resolution['height']!;
//
//     String? command;
//     String? filterComplex;
//
//     if (topOverlayPath != null) {
//       filterComplex =
//           // Scale top overlay to video width
//           "[1:v]scale=$videoWidth:-1[top];"
//
//           // Scale bottom overlay to video width
//           "[2:v]scale=$videoWidth:-1[bottom];"
//
//           // Stack top + original video
//           "[top][0:v]vstack=inputs=2[v1];"
//
//           // Overlay bottom at bottom
//           "[v1][bottom]overlay=0:H-h[v2];"
//
//           // 🔥 Force EVEN dimensions (IMPORTANT FIX)
//           "[v2]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
//
//       command = "-y "
//           "-i \"$videoPath\" "
//           "-i \"$topOverlayPath\" "
//           "-i \"$bottomOverlayPath\" "
//           "-filter_complex \"$filterComplex\" "
//           "-map \"[v]\" "
//           "-map 0:a? "
//           "-c:v libx264 "
//           "-preset veryfast "
//           "-crf 18 "
//           "-pix_fmt yuv420p "
//           "-movflags +faststart "
//           "-c:a copy "
//           "-shortest "
//           "\"$outputPath\"";
//     } else {
//       filterComplex =
//           // Scale bottom overlay
//           "[1:v]scale=$videoWidth:-1[bottom];"
//
//           // Overlay on video
//           "[0:v][bottom]overlay=0:H-h[v1];"
//
//           // 🔥 Force EVEN dimensions
//           "[v1]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
//
//       command = "-y "
//           "-i \"$videoPath\" "
//           "-i \"$bottomOverlayPath\" "
//           "-filter_complex \"$filterComplex\" "
//           "-map \"[v]\" "
//           "-map 0:a? "
//           "-c:v libx264 "
//           "-preset veryfast "
//           "-crf 18 "
//           "-pix_fmt yuv420p "
//           "-movflags +faststart "
//           "-c:a copy "
//           "-shortest "
//           "\"$outputPath\"";
//     }
//
//     final session = await FFmpegKit.execute(command);
//     final returnCode = await session.getReturnCode();
//
//     if (ReturnCode.isSuccess(returnCode)) {
//       return File(outputPath).existsSync() ? outputPath : null;
//     } else {
//       return null;
//     }
//   } catch (e) {
//     log("Merge error: $e");
//     return null;
//   }
// }
Future<String?> mergeVideoWithOverlay(
  String videoPath,
  String bottomOverlayPath, {
  String? topOverlayPath,
  String? animatedOverlayPath,
  required OverlayAnimationType animationType,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final outputPath =
        "${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.mp4";

    final resolution = await getVideoResolution(videoPath);
    if (resolution == null) return null;

    final duration = await getVideoDuration(videoPath);
    if (duration == null) return null;

    final int videoWidth = resolution['width']!;

    String inputs = "-i \"$videoPath\" ";
    String filter = "";
    int index = 1;

    /// Bottom overlay
    inputs += "-i \"$bottomOverlayPath\" ";
    filter += "[$index:v]scale=$videoWidth:-1[bottom];";
    index++;

    /// Top overlay
    if (topOverlayPath != null) {
      inputs += "-i \"$topOverlayPath\" ";
      filter += "[$index:v]scale=$videoWidth:-1[top];";
      index++;
    }

    /// Animated overlay (LIMITED by duration)
    if (animatedOverlayPath != null) {
      inputs += "-loop 1 -t $duration -i \"$animatedOverlayPath\" ";
      filter += "[$index:v]scale=$videoWidth:-1[anim];";
      index++;
    }

    /// ---- STACKING ----
    if (topOverlayPath != null) {
      filter += "[top][0:v]vstack=inputs=2[v1];"
          "[v1][bottom]overlay=0:H-h[v2];";
    } else {
      filter += "[0:v][bottom]overlay=0:H-h[v2];";
    }

    /// ---- ANIMATION ----
    if (animatedOverlayPath != null) {
      final animationExpr = buildOverlayAnimation(animationType, duration);

      filter += "[v2][anim]overlay=$animationExpr[v3];"
          "[v3]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
    } else {
      filter += "[v2]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
    }

    final command = "-y "
        "$inputs "
        "-filter_complex \"$filter\" "
        "-map \"[v]\" "
        "-map 0:a? "
        "-c:v libx264 "
        "-preset veryfast "
        "-crf 18 "
        "-pix_fmt yuv420p "
        "-movflags +faststart "
        "-c:a copy "
        "\"$outputPath\"";

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath).existsSync() ? outputPath : null;
    }

    return null;
  } catch (e) {
    rethrow;
  }
}

Future<double?> getVideoDuration(String path) async {
  try {
    final session = await FFprobeKit.execute(
      '-v error -show_entries format=duration '
      '-of default=noprint_wrappers=1:nokey=1 "$path"',
    );

    final output = await session.getOutput();

    if (output == null || output.trim().isEmpty) return null;

    return double.tryParse(output.trim());
  } catch (_) {
    return null;
  }
}

/// ===============================
/// SHARE VIDEO
/// ===============================
///

Future<void> shareVideo(String path) async {
  final params = ShareParams(
    text: 'Great picture',
    files: [
      XFile(
        path,
        mimeType: "video/mp4",
      )
    ],
  );
  await SharePlus.instance.share(params);
}

///
/// Custom animation merger
///
String buildOverlayAnimation(
  OverlayAnimationType type,
  double duration,
) {
  switch (type) {
    case OverlayAnimationType.topToCenter:
      return "x=(main_w-overlay_w)/2:"
          "y=if(lt(t\\,2)\\,-overlay_h+t*(main_h/2)\\,(main_h-overlay_h)/2)";

    case OverlayAnimationType.bottomToCenter:
      return "x=(main_w-overlay_w)/2:"
          "y=if(lt(t\\,2)\\,main_h-t*(main_h/2)\\,(main_h-overlay_h)/2)";

    case OverlayAnimationType.leftToRight:
      return "x=if(lt(t\\,2)\\,-overlay_w+t*(main_w/2)\\,(main_w-overlay_w)/2):"
          "y=(main_h-overlay_h)/2";

    case OverlayAnimationType.rightToLeft:
      return "x=if(lt(t\\,2)\\,main_w-t*(main_w/2)\\,(main_w-overlay_w)/2):"
          "y=(main_h-overlay_h)/2";

    case OverlayAnimationType.centerToTopRight:
      return "x=if(lt(t\\,2)\\,(main_w-overlay_w)/2 + t*(main_w/2)\\,main_w-overlay_w):"
          "y=if(lt(t\\,2)\\,(main_h-overlay_h)/2 - t*(main_h/2)\\,0)";

    case OverlayAnimationType.diagonalTopLeftToBottomRight:
      return "x=if(lt(t\\,2)\\,-overlay_w+t*(main_w/2)\\,(main_w-overlay_w)/2):"
          "y=if(lt(t\\,2)\\,-overlay_h+t*(main_h/2)\\,(main_h-overlay_h)/2)";

    case OverlayAnimationType.none:
    default:
      return "x=(main_w-overlay_w)/2:"
          "y=(main_h-overlay_h)/2";
  }
}
