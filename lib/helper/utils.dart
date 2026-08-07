import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'overlay_animation_type.dart';

/// ===============================
/// CAPTURE OVERLAY (High Quality)
/// ===============================
///
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

///
///convert text to tts audio
///
Future<String?> convertTextToSpeech(String title) async {
  try {
    final FlutterTts flutterTts = FlutterTts();
    final String fileName = "tts_${DateTime.now().millisecondsSinceEpoch}.mp3";

    await flutterTts.setLanguage("hi-IN");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSynthCompletion(true);

    /// Hindi voice selection
    List<dynamic> voices = await flutterTts.getVoices;
    for (var voice in voices) {
      if (voice is Map &&
          voice['locale'] == 'hi-IN' &&
          voice['name'].toString().contains('x-hie')) {
        await flutterTts.setVoice({
          'name': voice['name'],
          'locale': voice['locale'],
        });
        break;
      }
    }

    final result = await flutterTts.synthesizeToFile(title, fileName);

    if (result != 1) return null;

    /// Android common save locations
    final possibleDirs = [
      "/storage/emulated/0/Music/",
      "/storage/emulated/0/Ringtones/",
      "/storage/emulated/0/Download/",
    ];

    String? finalPath;

    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));

      for (final dir in possibleDirs) {
        final file = File("$dir$fileName");
        if (await file.exists()) {
          finalPath = file.path;
          break;
        }
      }

      if (finalPath != null) break;
    }

    return finalPath;
  } catch (e) {
    // print("TTS ERROR: $e");
    return null;
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
    if (await videoFile.exists()) {
      return videoFile.path;

      /// Already downloaded
    }

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

/// ===============================
/// MERGE VIDEO + OVERLAY (Optimal)
/// ===============================
Future<String?> mergeVideoWithOverlay(
  String videoPath,
  String? bottomOverlayPath, {
  String? topOverlayPath,
  String? animatedOverlayPath,
  String? overlayWidgetPath,
  Offset? overlayWidgetOffSet,
  String? overlayWidgetPath1,
  Offset? overlayWidgetOffSet1,
  String? audioFilePath,
  required OverlayAnimationData animationData,
  void Function(double progress)? onProgress,
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

    List<String> inputs = ["-i \"$videoPath\""];
    List<String> filterSteps = [];
    int inputIndex = 1;

    /// Bottom overlay (optional)
    String? bottomLabel;
    if (bottomOverlayPath != null) {
      inputs.add("-i \"$bottomOverlayPath\"");
      filterSteps.add("[$inputIndex:v]scale=$videoWidth:-1[bottom]");
      bottomLabel = "[bottom]";
      inputIndex++;
    }

    /// Top overlay (optional)
    String? topLabel;
    if (topOverlayPath != null) {
      inputs.add("-i \"$topOverlayPath\"");
      filterSteps.add("[$inputIndex:v]scale=$videoWidth:-1[top]");
      topLabel = "[top]";
      inputIndex++;
    }

    /// Animated overlay (optional)
    String? animLabel;
    if (animatedOverlayPath != null) {
      inputs.add("-loop 1 -t $duration -i \"$animatedOverlayPath\"");
      filterSteps.add("[$inputIndex:v]scale=$videoWidth:-1[anim]");
      animLabel = "[anim]";
      inputIndex++;
    }

    /// Overlay widgets
    String? widgetLabel;
    if (overlayWidgetPath != null) {
      inputs.add("-i \"$overlayWidgetPath\"");
      filterSteps.add("[$inputIndex:v]scale=$videoWidth:-1[widget]");
      widgetLabel = "[widget]";
      inputIndex++;
    }

    String? widgetLabel1;
    if (overlayWidgetPath1 != null) {
      inputs.add("-i \"$overlayWidgetPath1\"");
      filterSteps.add("[$inputIndex:v]scale=$videoWidth:-1[widget1]");
      widgetLabel1 = "[widget1]";
      inputIndex++;
    }

    /// Audio input
    int? audioInputIndex;
    if (audioFilePath != null) {
      inputs.add("-i \"$audioFilePath\"");
      audioInputIndex = inputIndex;
      inputIndex++;
    }

    /// Start building the filter complex graph
    String currentV = "[0:v]";
    filterSteps.add("$currentV setpts=PTS-STARTPTS[base]");
    currentV = "[base]";

    /// 1. Apply Bottom Overlay
    if (bottomLabel != null) {
      filterSteps.add("$currentV$bottomLabel overlay=0:H-h[v_bottom]");
      currentV = "[v_bottom]";
    }

    /// 2. Apply Animated Overlay
    if (animLabel != null) {
      final animationExpr = buildCustomAnimation(
        animData: animationData,
        resolution: resolution,
      );
      filterSteps.add("$currentV$animLabel overlay=$animationExpr[v_anim]");
      currentV = "[v_anim]";
    }

    /// 3. Apply Overlay Widget 1
    if (widgetLabel != null) {
      final x = endX(overlayWidgetOffSet?.dx ?? 0);
      final y = endY(overlayWidgetOffSet?.dy ?? 0);
      filterSteps.add("$currentV$widgetLabel overlay=x=$x:y=$y[v_w1]");
      currentV = "[v_w1]";
    }

    /// 4. Apply Overlay Widget 2
    if (widgetLabel1 != null) {
      final x = endX(overlayWidgetOffSet1?.dx ?? 0);
      final y = endY(overlayWidgetOffSet1?.dy ?? 0);
      filterSteps.add("$currentV$widgetLabel1 overlay=x=$x:y=$y[v_w2]");
      currentV = "[v_w2]";
    }

    /// 5. Apply Top Overlay (vstack)
    if (topLabel != null) {
      filterSteps.add("$topLabel$currentV vstack=inputs=2[v_stacked]");
      currentV = "[v_stacked]";
    }

    /// 6. Ensure even dimensions for libx264
    filterSteps.add("$currentV scale=trunc(iw/2)*2:trunc(ih/2)*2[final_v]");

    /// Audio Processing: Mix TTS with original audio if present
    String audioMapping = "";
    if (audioFilePath != null && audioInputIndex != null) {
      // amix mixes the audio streams. duration=first ensures it doesn't extend beyond the video.
      filterSteps.add(
          "[0:a][$audioInputIndex:a]amix=inputs=2:duration=first:dropout_transition=2[a]");
      audioMapping = "-map \"[a]\" -c:a aac -b:a 128k";
    } else {
      audioMapping = "-map 0:a? -c:a copy";
    }

    final filterComplex = filterSteps.join(";");
    final command = "-y ${inputs.join(" ")} "
        "-filter_complex \"$filterComplex\" "
        "-map \"[final_v]\" $audioMapping "
        "-c:v libx264 -preset ultrafast -crf 23 "
        "-pix_fmt yuv420p -movflags +faststart "
        "\"$outputPath\"";

    log("FFmpeg Command: $command");

    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback((stats) {
        final timeInMs = stats.getTime();
        if (timeInMs > 0) {
          double progress = timeInMs / (duration * 1000);
          if (progress > 1.0) progress = 1.0;
          onProgress(progress);
        }
      });
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback(null);
    }

    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath).existsSync() ? outputPath : null;
    } else {
      final logs = await session.getAllLogsAsString();
      log("FFmpeg Failed: $logs");
      return null;
    }
  } catch (e) {
    log("Merge Error: $e");
    return null;
  }
}

///
/// Custom animation merger
///

class OverlayPoint {
  final double x;
  final double y;

  const OverlayPoint(this.x, this.y);
}

///new logic

String startX(double value) {
  return "(main_w+overlay_w)*$value-overlay_w";
}

String startY(double value) {
  return "(main_h+overlay_h)*$value-overlay_h";
}

String endX(double value) {
  return "(main_w-overlay_w)*$value";
}

String endY(double value) {
  return "(main_h-overlay_h)*$value";
}

String buildCustomAnimation({
  required OverlayAnimationData animData,
  required resolution,
}) {
  final start = animData.startOffset;
  final end = animData.endOffset;

  final startTime = animData.startDuration.inMilliseconds / 1000.0;
  final duration = animData.duration.inMilliseconds / 1000.0;

  final sx = startX(start.dx);
  final sy = startY(start.dy);

  final ex = endX(end.dx);
  final ey = endY(end.dy);

  final progress = "if(lt(t\\,$startTime)\\,0\\,"
      "if(gte(t\\,${startTime + duration})\\,1\\,"
      "(3*((t-$startTime)/$duration)^2-2*((t-$startTime)/$duration)^3)"
      "))";
  return "x=($sx)+(($ex)-($sx))*($progress):"
      "y=($sy)+(($ey)-($sy))*($progress)";
}
// String buildCustomAnimation({
//   required OverlayAnimationData animData,
//   required resolution,
// }) {
//   final start = animData.startOffset;
//   log("ddddddd start ${start.dx} and ${start.dy}");
//   final end = animData.endOffset;
//   final duration = animData.duration.inMilliseconds / 1000.0;
//
//   final progress = "if(lt(t\\,$duration)\\,"
//       "(3*(t/$duration)*(t/$duration)-2*(t/$duration)*(t/$duration)*(t/$duration))"
//       "\\,1)";
//   final sx = startX(start.dx);
//   final sy = startY(start.dy);
//
//   final ex = endX(end.dx);
//   final ey = endY(end.dy);
//
//   return "x=($sx)+(($ex)-($sx))*($progress):"
//       "y=($sy)+(($ey)-($sy))*($progress)";
// }
