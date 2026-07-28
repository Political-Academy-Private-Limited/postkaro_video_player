import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
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

    /// Bottom overlay (optional)
    if (bottomOverlayPath != null) {
      inputs += "-i \"$bottomOverlayPath\" ";
      filter += "[$index:v]scale=$videoWidth:-1[bottom];";
      index++;
    }

    /// Top overlay (optional)
    if (topOverlayPath != null) {
      inputs += "-i \"$topOverlayPath\" ";
      filter += "[$index:v]scale=$videoWidth:-1[top];";
      index++;
    }

    /// Animated overlay (optional)
    if (animatedOverlayPath != null) {
      inputs += "-loop 1 -t $duration -i \"$animatedOverlayPath\" ";
      filter += "[$index:v]scale=$videoWidth:-1[anim];";
      index++;
    }

    /// Overlay widget (optional)
    if (overlayWidgetPath != null) {
      inputs += "-i \"$overlayWidgetPath\" ";
      // filter += "[$index:v]scale=-1:-1[widget];";
      filter += "[$index:v]scale=$videoWidth:-1[widget];";
      index++;
    }

    /// Overlay widget1 (optional)
    if (overlayWidgetPath1 != null) {
      inputs += "-i \"$overlayWidgetPath1\" ";
      // filter += "[$index:v]scale=-1:-1[widget];";
      filter += "[$index:v]scale=$videoWidth:-1[widget1];";
      index++;
    }

    /// Audio input (optional)
    int? audioIndex;
    if (audioFilePath != null) {
      inputs += "-i \"$audioFilePath\" ";
      audioIndex = index;
      index++;
    }

    /// Base video
    filter += "[0:v]setpts=PTS-STARTPTS[base];";

    /// Bottom overlay
    if (bottomOverlayPath != null) {
      filter += "[base][bottom]overlay=0:H-h[baseWithBottom];";
    } else {
      filter += "[base]copy[baseWithBottom];";
    }

    /// Animated overlay
    if (animatedOverlayPath != null) {
      final animationExpr = buildCustomAnimation(
        animData: animationData,
        resolution: resolution,
      );

      filter += "[baseWithBottom][anim]overlay=$animationExpr[animated];";
      // final startTime = animationData.startDuration.inMilliseconds / 1000.0;
      //
      // filter += "[baseWithBottom][anim]overlay="
      //     "$animationExpr:"
      //     "enable='gte(t,$startTime)'"
      //     "[animated];";
    } else {
      filter += "[baseWithBottom]copy[animated];";
    }

    /// Overlay widget
    if (overlayWidgetPath != null) {
      final dx = overlayWidgetOffSet?.dx ?? 0;
      final dy = overlayWidgetOffSet?.dy ?? 0;

      final x = endX(dx);
      final y = endY(dy);

      filter += "[animated][widget]overlay="
          "x=$x:"
          "y=$y"
          "[widgetApplied];";
    } else {
      filter += "[animated]copy[widgetApplied];";
    }

    /// Overlay widget
    if (overlayWidgetPath1 != null) {
      final dx = overlayWidgetOffSet1?.dx ?? 0;
      final dy = overlayWidgetOffSet1?.dy ?? 0;

      final x = endX(dx);
      final y = endY(dy);

      filter += "[widgetApplied][widget1]overlay="
          "x=$x:"
          "y=$y"
          "[widgetApplied1];";
    } else {
      filter += "[widgetApplied]copy[widgetApplied1];";
    }

    /// Top overlay
    if (topOverlayPath != null) {
      filter += "[top][animated]vstack=inputs=2[stacked];"
          "[stacked]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
    } else {
      // filter += "[animated]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
      // filter += "[widgetApplied]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
      filter += "[widgetApplied1]scale=trunc(iw/2)*2:trunc(ih/2)*2[v]";
    }

    /// Audio mapping
    String audioMap;
    String audioCodec;

    if (audioFilePath != null && audioIndex != null) {
      audioMap = "-map $audioIndex:0";
      audioCodec = "-c:a aac -t $duration";
    } else {
      audioMap = "-map 0:a?";
      audioCodec = "-c:a copy";
    }

    final command = "-y "
        "$inputs "
        "-filter_complex \"$filter\" "
        "-map \"[v]\" "
        "$audioMap "
        "-c:v libx264 "
        "-preset veryfast "
        "-crf 18 "
        "-pix_fmt yuv420p "
        "-movflags +faststart "
        "$audioCodec "
        "\"$outputPath\"";

    final session = await FFmpegKit.execute(command);
    final logs = await session.getAllLogsAsString();
    log(logs.toString());

    final failStack = await session.getFailStackTrace();
    log(failStack.toString());

    log(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath).existsSync() ? outputPath : null;
    }

    return null;
  } catch (e) {
    rethrow;
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
