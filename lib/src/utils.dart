import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> captureOverlay(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;

  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ImageByteFormat.png);

  final pngBytes = byteData!.buffer.asUint8List();

  final dir = await getTemporaryDirectory();
  final filePath =
      "${dir.path}/overlay_${DateTime.now().millisecondsSinceEpoch}.png";

  final file = File(filePath);
  await file.writeAsBytes(pngBytes);

  return filePath;
}

Future<String?> downloadVideo(String videoUrl) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final videoFileName = videoUrl.split('/').last.split('?').first;

    final videoFile = File('${tempDir.path}/$videoFileName');

    final response = await http.get(Uri.parse(videoUrl));

    if (response.statusCode == 200) {
      await videoFile.writeAsBytes(response.bodyBytes);

      print("Video downloaded at: ${videoFile.path}");
      print("File exists after download: ${videoFile.existsSync()}");

      return videoFile.path;
    } else {
      print("Download failed with status: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Download error: $e");
    return null;
  }
}

Future<String?> mergeVideoWithOverlay(
  String videoPath,
  String overlayPath,
) async {
  final dir = await getTemporaryDirectory();
  final outputPath =
      "${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.mp4";

  final command =
      '-y -i "$videoPath" '
      '-i "$overlayPath" '
      '-filter_complex "overlay=x=0:y=main_h-overlay_h" '
      '-c:v libx264 -preset veryfast -crf 23 '
      '-c:a copy '
      '"$outputPath"';


  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();

  print("FFmpeg return code: $returnCode");

  if (ReturnCode.isSuccess(returnCode)) {
    if (File(outputPath).existsSync()) {
      print("File created successfully");
      return outputPath;
    } else {
      print("File not found after success");
      return null;
    }
  } else {
    final logs = await session.getAllLogs();
    print("FFmpeg failed:");
    for (var log in logs) {
      print(log.getMessage());
    }
    return null;
  }
}

Future<void> exportFinalVideo(String url, GlobalKey overlayKey) async {
  final videoPath = await downloadVideo(url);

  final overlayPath = await captureOverlay(overlayKey);
  if(videoPath !=null) {
    await mergeVideoWithOverlay(videoPath, overlayPath);
  }else{
    log("video download fail");
  }
}

Future<void> shareVideo(String path) async {
  await Share.shareXFiles(
    [XFile(path)],
    text: "Check this out!",
  );
}
