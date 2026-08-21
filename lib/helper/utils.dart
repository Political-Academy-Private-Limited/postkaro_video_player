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

/// Result of capturing an overlay widget for export.
class CapturedOverlay {
  final String path;

  /// Logical size of the captured widget (same units as the player layout).
  final Size logicalSize;

  const CapturedOverlay({
    required this.path,
    required this.logicalSize,
  });
}

int _even(int value) {
  if (value < 2) return 2;
  return value - (value % 2);
}

/// Maps an on-screen logical size into exact video pixel dimensions.
Size overlayPixelSize({
  required Size overlayLogical,
  required Size playerLogical,
  required int videoWidth,
  required int videoHeight,
}) {
  if (playerLogical.width <= 0 || playerLogical.height <= 0) {
    return Size(videoWidth.toDouble(), videoHeight.toDouble());
  }

  final w = (overlayLogical.width / playerLogical.width * videoWidth).round();
  final h =
      (overlayLogical.height / playerLogical.height * videoHeight).round();
  return Size(_even(w).toDouble(), _even(h).toDouble());
}

/// ===============================
/// CAPTURE OVERLAY
/// ===============================
Future<CapturedOverlay?> captureOverlay(
  GlobalKey key,
  String fileName, {
  double? pixelRatio,
}) async {
  try {
    if (key.currentContext == null) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (key.currentContext == null) return null;
    }

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null || boundary.size.isEmpty) return null;

    final logicalSize = boundary.size;
    final mediaDpr = MediaQuery.maybeOf(key.currentContext!)?.devicePixelRatio;
    final dpr = pixelRatio ?? mediaDpr ?? 2.0;

    // Higher ratio = sharper overlay (lanczos downscales cleanly later)
    final ratio = dpr.clamp(2.0, 6.0);

    await Future.delayed(const Duration(milliseconds: 16));

    final ui.Image image = await boundary.toImage(pixelRatio: ratio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) return null;

    final Directory tempDir = await getTemporaryDirectory();
    final File imageFile = File('${tempDir.path}/${fileName}_overlay.png');
    await imageFile.writeAsBytes(byteData.buffer.asUint8List(), flush: false);

    return CapturedOverlay(path: imageFile.path, logicalSize: logicalSize);
  } catch (e) {
    rethrow;
  }
}

Size? readWidgetSize(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || box.size.isEmpty) return null;
  return box.size;
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

    String? finalPath;

    if (Platform.isAndroid) {
      /// Android common save locations for synthesized files
      final possibleDirs = [
        "/storage/emulated/0/Music/",
        "/storage/emulated/0/Ringtones/",
        "/storage/emulated/0/Download/",
      ];

      for (int i = 0; i < 15; i++) {
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
    } else if (Platform.isIOS) {
      /// On iOS, the file is usually saved in the app's documents directory
      final Directory docDir = await getApplicationDocumentsDirectory();
      final file = File("${docDir.path}/$fileName");

      // Wait a bit for synthesis to complete and file to be written
      for (int i = 0; i < 15; i++) {
        if (await file.exists()) {
          finalPath = file.path;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
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
/// GET VIDEO INFO
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
    return null;
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

Future<double> getVideoFps(String path) async {
  try {
    final session = await FFprobeKit.execute(
      '-v error -select_streams v:0 '
      '-show_entries stream=r_frame_rate '
      '-of default=noprint_wrappers=1:nokey=1 "$path"',
    );
    final output = (await session.getOutput())?.trim();
    if (output == null || output.isEmpty) return 30;

    if (output.contains('/')) {
      final parts = output.split('/');
      final num_ = double.tryParse(parts[0]) ?? 30;
      final den = double.tryParse(parts[1]) ?? 1;
      if (den == 0) return 30;
      final fps = num_ / den;
      if (fps.isNaN || fps <= 0 || fps > 120) return 30;
      return fps;
    }
    return double.tryParse(output) ?? 30;
  } catch (_) {
    return 30;
  }
}

Future<({int width, int height, double duration, double fps})?> getVideoInfo(
  String path,
) async {
  final resolution = await getVideoResolution(path);
  final duration = await getVideoDuration(path);
  if (resolution == null || duration == null) return null;
  final fps = await getVideoFps(path);
  return (
    width: resolution['width']!,
    height: resolution['height']!,
    duration: duration,
    fps: fps,
  );
}

/// ===============================
/// SHARE VIDEO
/// ===============================
Future<void> shareVideo(String path, String? shareText) async {
  final params = ShareParams(
    text: shareText,
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
/// MERGE VIDEO + OVERLAY
/// ===============================
Future<String?> mergeVideoWithOverlay(
  String videoPath,
  CapturedOverlay? bottomOverlay, {
  CapturedOverlay? topOverlay,
  CapturedOverlay? animatedOverlay,
  CapturedOverlay? overlayWidget,
  Offset? overlayWidgetOffSet,
  CapturedOverlay? overlayWidget1,
  Offset? overlayWidgetOffSet1,
  String? audioFilePath,
  required OverlayAnimationData animationData,
  Size? animSize,
  Size? playerLogicalSize,
  int? videoWidth,
  int? videoHeight,
  double? videoDuration,
  double? videoFps,
  void Function(double progress)? onProgress,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final outputPath =
        "${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.mp4";

    late final int vw;
    late final int vh;
    late final double duration;
    late final double fps;

    if (videoWidth != null && videoHeight != null && videoDuration != null) {
      vw = videoWidth;
      vh = videoHeight;
      duration = videoDuration;
      fps = videoFps ?? await getVideoFps(videoPath);
    } else {
      final info = await getVideoInfo(videoPath);
      if (info == null) return null;
      vw = info.width;
      vh = info.height;
      duration = info.duration;
      fps = info.fps;
    }

    // Animate at least at source fps (min 30) so motion isn't stepped
    final animFps = fps < 30 ? 30.0 : fps;

    final playerSize = playerLogicalSize;
    final Size? derivedAnimSize = (animatedOverlay != null &&
            playerSize != null &&
            playerSize.width > 0 &&
            playerSize.height > 0)
        ? Size(
            animatedOverlay.logicalSize.width / playerSize.width,
            animatedOverlay.logicalSize.height / playerSize.height,
          )
        : animSize;

    List<String> inputs = ["-i \"$videoPath\""];
    List<String> filterSteps = [];
    int inputIndex = 1;

    String scaleHq(int index, String label, {required String sizeExpr}) {
      return "[$index:v]scale=$sizeExpr:flags=lanczos:param0=3[$label]";
    }

    String? bottomLabel;
    if (bottomOverlay != null) {
      inputs.add("-i \"${bottomOverlay.path}\"");
      filterSteps.add(scaleHq(inputIndex, "bottom", sizeExpr: "$vw:-2"));
      bottomLabel = "[bottom]";
      inputIndex++;
    }

    String? topLabel;
    if (topOverlay != null) {
      inputs.add("-i \"${topOverlay.path}\"");
      filterSteps.add(scaleHq(inputIndex, "top", sizeExpr: "$vw:-2"));
      topLabel = "[top]";
      inputIndex++;
    }

    String? animLabel;
    if (animatedOverlay != null) {
      // High framerate still loop — without this, animation is choppy
      inputs.add(
        "-loop 1 -framerate $animFps -t $duration -i \"${animatedOverlay.path}\"",
      );
      final Size target;
      if (playerSize != null) {
        target = overlayPixelSize(
          overlayLogical: animatedOverlay.logicalSize,
          playerLogical: playerSize,
          videoWidth: vw,
          videoHeight: vh,
        );
      } else if (derivedAnimSize != null) {
        target = Size(
          _even((vw * derivedAnimSize.width).round()).toDouble(),
          _even((vh * derivedAnimSize.height).round()).toDouble(),
        );
      } else {
        target = Size(vw.toDouble(), vh.toDouble());
      }
      final tw = target.width.toInt().clamp(2, vw);
      final th = target.height.toInt().clamp(2, vh);
      filterSteps.add(
        scaleHq(
          inputIndex,
          "anim",
          sizeExpr: "${_even(tw)}:${_even(th)}",
        ),
      );
      animLabel = "[anim]";
      inputIndex++;
    }

    String? widgetLabel;
    if (overlayWidget != null) {
      inputs.add("-i \"${overlayWidget.path}\"");
      filterSteps.add(
        scaleHq(inputIndex, "widget", sizeExpr: "${_even(vw)}:${_even(vh)}"),
      );
      widgetLabel = "[widget]";
      inputIndex++;
    }

    String? widgetLabel1;
    if (overlayWidget1 != null) {
      inputs.add("-i \"${overlayWidget1.path}\"");
      filterSteps.add(
        scaleHq(inputIndex, "widget1", sizeExpr: "${_even(vw)}:${_even(vh)}"),
      );
      widgetLabel1 = "[widget1]";
      inputIndex++;
    }

    int? audioInputIndex;
    if (audioFilePath != null) {
      inputs.add("-i \"$audioFilePath\"");
      audioInputIndex = inputIndex;
      inputIndex++;
    }

    String currentV = "[0:v]";

    if (bottomLabel != null) {
      filterSteps
          .add("$currentV$bottomLabel overlay=0:H-h:format=auto[v_bottom]");
      currentV = "[v_bottom]";
    }

    if (animLabel != null) {
      final animationExpr = buildCustomAnimation(
        animData: animationData,
        animSize: derivedAnimSize,
      );
      filterSteps.add(
        "$currentV$animLabel overlay=$animationExpr:format=auto[v_anim]",
      );
      currentV = "[v_anim]";
    }

    if (widgetLabel != null) {
      filterSteps.add("$currentV$widgetLabel overlay=0:0:format=auto[v_w1]");
      currentV = "[v_w1]";
    }

    if (widgetLabel1 != null) {
      filterSteps.add("$currentV$widgetLabel1 overlay=0:0:format=auto[v_w2]");
      currentV = "[v_w2]";
    }

    if (topLabel != null) {
      filterSteps.add("$topLabel$currentV vstack=inputs=2[v_stacked]");
      currentV = "[v_stacked]";
    }

    filterSteps.add("$currentV scale=trunc(iw/2)*2:trunc(ih/2)*2:flags=lanczos[final_v]");
    const finalLabel = "[final_v]";

    String audioMapping;
    if (audioFilePath != null && audioInputIndex != null) {
      filterSteps.add(
        "[0:a][$audioInputIndex:a]amix=inputs=2:duration=first:dropout_transition=2[a]",
      );
      audioMapping = '-map "[a]" -c:a aac -b:a 128k';
    } else {
      audioMapping = "-map 0:a? -c:a copy";
    }

    // Higher quality encode (still relatively fast)
    const vCodec = "libx264";
    const vCodecParams = "-preset veryfast -crf 18";

    final filterComplex = filterSteps.join(";");
    final command = "-y ${inputs.join(" ")} "
        "-filter_complex \"$filterComplex\" "
        "-map \"$finalLabel\" $audioMapping "
        "-c:v $vCodec $vCodecParams "
        "-pix_fmt yuv420p -movflags +faststart "
        "\"$outputPath\"";

    debugPrint("Export FFmpeg: $command");

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
    }

    debugPrint("Export FFmpeg failed: ${await session.getAllLogsAsString()}");
    return null;
  } catch (e, st) {
    debugPrint("Export merge error: $e\n$st");
    return null;
  }
}

String startX(double value) => "(W-w)*$value";

String startY(double value) => "(H-h)*$value";

String endX(double value) => "(W-w)*$value";

String endY(double value) => "(H-h)*$value";

String buildCustomAnimation({
  required OverlayAnimationData animData,
  Size? animSize,
}) {
  final start = animData.withOutsideStart(animSize).startOffset;
  final end = animData.endOffset;

  final startTime = animData.startDuration.inMilliseconds / 1000.0;
  final durationSec = animData.duration.inMilliseconds / 1000.0;

  final sx = startX(start.dx);
  final sy = startY(start.dy);
  final ex = endX(end.dx);
  final ey = endY(end.dy);

  final p = "((t-$startTime)/$durationSec)";
  final progress = "if(lt(t,$startTime),0,"
      "if(gte(t,${startTime + durationSec}),1,"
      "(3*$p*$p-2*$p*$p*$p)"
      "))";
  return "x='$sx+($ex-($sx))*($progress)':"
      "y='$sy+($ey-($sy))*($progress)'";
}
