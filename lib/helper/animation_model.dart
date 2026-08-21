import 'package:flutter/material.dart';

import '../houseoftech_video_player.dart';

class AnimationModel {
  final String url;

  final HouseOfTechController? controller;

  final Widget? bottomStripe;

  final Widget? topStripe;

  final VoidCallback? onDownload;

  final VoidCallback? onShare;

  final void Function(bool success)? onDownloadComplete;

  final void Function(bool success)? onShareComplete;

  final double right;

  final bool reelsMode;

  final bool autoPlay;

  final bool loop;

  final bool isMute;

  final Widget? videoLoader;

  final double aspectRatio;

  final Icon? downloadIcon;
  final Icon? shareIcon;

  final Color? downloadBackgroundColor;

  final Color? shareBackgroundColor;

  final Widget? animatedOverlay;

  final Widget? overlayWidget;
  final Offset? overlayPosition;

  final Widget? overlayWidget1;
  final Offset? overlayPosition1;

  final OverlayAnimationData? animationData;

  final Widget? shareDownloadProgressIndicator;

  final bool downloadWithOverlay;

  final void Function(bool isLoading, double progress)? onStatusChanged;

  final void Function(double progress)? onExportProgress;

  final double top;
  final double bottom;
  final double? left;

  final double spaceBwDownShare;

  final VideoRouteObserver? videoRouteObserver;

  final String? folderName;

  final String? ttsText;

  final String? shareText;

  AnimationModel({
    required this.url,
    this.controller,
    this.bottomStripe,
    this.onDownload,
    this.overlayWidget,
    this.overlayWidget1,
    // this.overlayChild,
    this.onShare,
    this.reelsMode = false,
    this.autoPlay = false,
    this.loop = false,
    this.right = 6,
    this.topStripe,
    this.aspectRatio = 9 / 16,
    this.downloadIcon,
    this.shareIcon,
    this.downloadBackgroundColor,
    this.shareBackgroundColor,
    this.animatedOverlay,
    this.animationData,
    this.shareDownloadProgressIndicator,
    this.downloadWithOverlay = false,
    this.onStatusChanged,
    this.videoRouteObserver,
    this.onDownloadComplete,
    this.onShareComplete,
    this.top = 0,
    this.bottom = 0,
    this.left,
    this.spaceBwDownShare = 16,
    this.folderName,
    this.ttsText,
    this.isMute = false,
    this.videoLoader,
    this.overlayPosition,
    this.overlayPosition1,
    this.onExportProgress,
    this.shareText,
  });
}
