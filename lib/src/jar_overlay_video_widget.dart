import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jar_video_player/src/utils.dart';
import 'package:jar_video_player/src/video_export_service.dart';
import 'package:media_store_plus/media_store_plus.dart';
import '../jar_video_player.dart';

class JarVideoPlayerOverlay extends StatefulWidget {
  final String url;
  final JarVideoPlayerController? controller;
  final Widget? bottomStripe;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final AlignmentGeometry downloadShareAlignment;
  final bool reelsMode;
  final bool autoPlay;
  final bool loop;

  const JarVideoPlayerOverlay({
    super.key,
    required this.url,
    this.controller,
    this.bottomStripe,
    this.onDownload,
    this.onShare,
    this.reelsMode = false,
    this.autoPlay = false,
    this.loop = false,
    this.downloadShareAlignment = Alignment.centerRight,
  });

  @override
  State<JarVideoPlayerOverlay> createState() => _JarVideoPlayerOverlayState();
}

class _JarVideoPlayerOverlayState extends State<JarVideoPlayerOverlay> {
  final GlobalKey _overlayKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _handleDownload() async {
    if (_isProcessing) return;

    debugPrint("DOWNLOAD CALLED");

    setState(() => _isProcessing = true);

    try {
      final path = await exportVideoWithOverlay(
        videoUrl: widget.url,
        overlayKey: _overlayKey,
      );

      if (path != null) {
        debugPrint("Export path: $path");
        debugPrint("File exists: ${File(path).existsSync()}");

        await MediaStore.ensureInitialized();
        MediaStore.appFolder = "JarVideoPlayer";

        final result = await MediaStore()
            .saveFile(
          tempFilePath: path,
          dirType: DirType.video,
          dirName: DirName.movies,
        )
            .then(
          (value) {
            log("download success");
          },
        );

        // final result = await MediaStore().saveFile(
        //   tempFilePath: path,
        //   dirType: DirType.video,
        //   dirName: DirName.movies,
        // );

        debugPrint("MediaStore result: $result");
      }
    } catch (e) {
      debugPrint("Download error: $e");
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isProcessing) return;

    debugPrint("SHARE CALLED");

    setState(() => _isProcessing = true);

    try {
      final path = await exportVideoWithOverlay(
        videoUrl: widget.url,
        overlayKey: _overlayKey,
      );

      if (path != null) {
        await shareVideo(path);
        widget.onShare?.call(); // optional external callback
      }
    } catch (e) {
      debugPrint("Share error: $e");
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          /// 🎥 VIDEO (Never inside RepaintBoundary)
          IgnorePointer(
            ignoring: _isProcessing,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: JarVideoPlayer(
                url: widget.url,
                controller: widget.controller,
                reelsMode: widget.reelsMode,
                autoPlay: widget.autoPlay,
                loop: widget.loop,
              ),
            ),
          ),

          /// 📌 Bottom Stripe (Captured Only This)
          if (widget.bottomStripe != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                key: _overlayKey,
                child: widget.bottomStripe!,
              ),
            ),

          /// 🔘 Buttons
          Align(
            alignment: widget.downloadShareAlignment,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: Icons.download,
                    onTap: _handleDownload,
                    disabled: _isProcessing,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.share,
                    onTap: _handleShare,
                    disabled: _isProcessing,
                  ),
                ],
              ),
            ),
          ),

          /// 🔥 Loader Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black54,
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
