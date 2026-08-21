import 'package:flutter/material.dart';
import 'package:houseoftech_video_player/houseoftech_video_player.dart';
import '../helper/animation_model.dart';

class HotAnimationVideo extends StatefulWidget {
  final AnimationModel animData;
  final Size? animSize;

  const HotAnimationVideo({super.key, required this.animData, this.animSize});

  @override
  State<HotAnimationVideo> createState() => _HotAnimationVideoState();
}

class _HotAnimationVideoState extends State<HotAnimationVideo> {
  @override
  void initState() {
    super.initState();
    overlayAnimationData = widget.animData.animationData;
    setOutside();
  }

  late OverlayAnimationData? overlayAnimationData;

  void setOutside() {
    final data = overlayAnimationData;
    final size = widget.animSize;

    if (data == null || size == null) {
      return;
    }

    final offset = data.startOffset;

    double x = offset.dx;
    double y = offset.dy;

    // X axis
    if (x <= 0) {
      x = x - size.width;
    } else if (x >= 1) {
      x = x + size.width;
    }

    // Y axis
    if (y <= 0) {
      y = y - size.height;
    } else if (y >= 1) {
      y = y + size.height;
    }

    overlayAnimationData = data.copyWith(
      startOffset: Offset(x, y),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HotVideoPlayerOverlay(
      url: widget.animData.url,
      controller: widget.animData.controller,
      bottomStripe: widget.animData.bottomStripe,
      topStripe: widget.animData.topStripe,
      onDownload: widget.animData.onDownload,
      onShare: widget.animData.onShare,
      onDownloadComplete: widget.animData.onDownloadComplete,
      onShareComplete: widget.animData.onShareComplete,
      right: widget.animData.right,
      reelsMode: widget.animData.reelsMode,
      autoPlay: widget.animData.autoPlay,
      loop: widget.animData.loop,
      isMute: widget.animData.isMute,
      videoLoader: widget.animData.videoLoader,
      aspectRatio: widget.animData.aspectRatio,
      downloadIcon: widget.animData.downloadIcon,
      shareIcon: widget.animData.shareIcon,
      downloadBackgroundColor: widget.animData.downloadBackgroundColor,
      shareBackgroundColor: widget.animData.shareBackgroundColor,
      animatedOverlay: widget.animData.animatedOverlay,
      overlayWidget: widget.animData.overlayWidget,
      overlayPosition: widget.animData.overlayPosition,
      overlayWidget1: widget.animData.overlayWidget1,
      overlayPosition1: widget.animData.overlayPosition1,
      animationData: overlayAnimationData,
      shareDownloadProgressIndicator:
          widget.animData.shareDownloadProgressIndicator,
      downloadWithOverlay: widget.animData.downloadWithOverlay,
      onStatusChanged: widget.animData.onStatusChanged,
      onExportProgress: widget.animData.onExportProgress,
      top: widget.animData.top,
      bottom: widget.animData.bottom,
      left: widget.animData.left,
      spaceBwDownShare: widget.animData.spaceBwDownShare,
      videoRouteObserver: widget.animData.videoRouteObserver,
      folderName: widget.animData.folderName,
      ttsText: widget.animData.ttsText,
      shareText: widget.animData.shareText,
    );
  }
}
