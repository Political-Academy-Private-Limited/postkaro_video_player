import 'package:flutter/material.dart';
import 'package:jar_video_player/helper/animation_widget.dart';
import 'package:jar_video_player/helper/utils.dart';
import 'package:jar_video_player/helper/video_export_service.dart';
import 'package:media_store_plus/media_store_plus.dart';
import '../jar_video_player.dart';

class JarVideoPlayerOverlay extends StatefulWidget {
  /// The network URL of the video to be played.
  ///
  /// This must be a valid video URL (e.g. mp4, m3u8).
  /// The video will be streamed using the underlying video player.
  final String url;

  /// Optional controller to control playback externally.
  ///
  /// If provided, you can manually control play, pause,
  /// mute, seek, and listen to state changes.
  /// If null, an internal controller will be created.
  final JarVideoPlayerController? controller;

  /// A widget displayed at the bottom of the video.
  ///
  /// Commonly used for captions, user info, buttons,
  /// or branding overlays.
  final Widget? bottomStripe;

  /// A widget displayed at the top of the video.
  ///
  /// Useful for showing titles, tags, or additional UI elements.
  final Widget? topStripe;

  /// Callback triggered when the download action is pressed.
  ///
  /// You can use this to implement custom download logic.
  final VoidCallback? onDownload;

  /// Callback triggered when the share action is pressed.
  ///
  /// Allows integration with share plugins or custom share logic.
  final VoidCallback? onShare;

  /// Called after download is completed.
  /// Returns true if download was successful.
  final void Function(bool success)? onDownloadComplete;

  /// Called after share is completed.
  /// Returns true if share was successful.
  final void Function(bool success)? onShareComplete;

  /// Distance from the right side for positioning overlay controls.
  ///
  /// Useful for adjusting layout in reels-style UI.
  final double right;

  /// Enables reels-style behavior.
  ///
  /// When true:
  /// - Video auto plays when visible
  /// - Video pauses when out of view
  /// - Optimized for vertical scrolling feeds
  ///
  final bool reelsMode;

  /// Determines whether the video should start playing automatically.
  ///
  /// Defaults to true in most reel scenarios.
  final bool autoPlay;

  /// Whether the video should loop after finishing.
  ///
  /// If true, the video restarts automatically.
  final bool loop;

  /// The aspect ratio of the video player.
  ///
  /// Defaults to 9/16 for reels.
  /// Example:
  /// - 16/9 for landscape videos
  /// - 1.0 for square videos
  ///
  final double aspectRatio;

  ///for download and share buttons
  ///all are optional
  final Icon? downloadIcon;
  final Icon? shareIcon;

  ///default background color is Colors.black54
  final Color? downloadBackgroundColor;

  ///share background is not necessary as it can user download background color
  final Color? shareBackgroundColor;

  ///
  ///for downloading in animated style
  ///
  final Widget? animatedOverlay;

  ///
  /// for selecting different animation type
  /// basically it is starting and end point
  /// when an widget will start animation and
  /// end the animation
  ///
  final OverlayAnimationType? animationType;

  ///
  ///custom progress indicator when video is being downloaded
  ///by default there is CircularProgressIndicator in center
  ///
  final Widget? shareDownloadProgressIndicator;

  ///download with custom overlays
  final bool downloadWithOverlay;

  ///
  final void Function(bool, double)? onStatusChanged;

  ///
  ///this is for route change play pause
  ///

  ///
  ///for custom download and share location
  ///
  final double top;
  final double bottom;
  final double? left;

  final VideoRouteObserver? videoRouteObserver;
  const JarVideoPlayerOverlay({
    super.key,
    required this.url,
    this.controller,
    this.bottomStripe,
    this.onDownload,
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
    this.animationType,
    this.shareDownloadProgressIndicator,
    this.downloadWithOverlay = false,
    this.onStatusChanged,
    this.videoRouteObserver,
    this.onDownloadComplete,
    this.onShareComplete,
    this.top = 0,
    this.bottom = 0,
    this.left,
  });

  @override
  State<JarVideoPlayerOverlay> createState() => _JarVideoPlayerOverlayState();
}

class _JarVideoPlayerOverlayState extends State<JarVideoPlayerOverlay> {
  final GlobalKey _bottomOverlayKey = GlobalKey();
  final GlobalKey _topOverlayKey = GlobalKey();
  final GlobalKey _animatedOverlayKey = GlobalKey();

  bool _isProcessing = false;
  bool isVideoLoading = false;
  double videoProgress = 0;

  ///this is for handling download
  Future<void> _handleDownload() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final path = await exportVideoWithOverlay(
        videoUrl: widget.url,
        bottomOverlayKey: _bottomOverlayKey,
        downloadWithOverlay: widget.downloadWithOverlay,
        topOverlayKey: widget.topStripe == null ? null : _topOverlayKey,
        animatedOverlayKey:
            widget.animatedOverlay == null ? null : _animatedOverlayKey,
        animationType: widget.animationType,
      );

      if (path != null) {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = "Overlay Video";

        await MediaStore().saveFile(
          tempFilePath: path,
          dirType: DirType.video,
          dirName: DirName.movies,
        );
        widget.onDownloadComplete?.call(true);
      }
    } catch (e) {
      widget.onDownloadComplete?.call(false);

      throw e.toString();
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  ///this is for download and share the video with or without overlay widget
  Future<void> _handleShare() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final path = await exportVideoWithOverlay(
        videoUrl: widget.url,
        bottomOverlayKey: _bottomOverlayKey,
        downloadWithOverlay: widget.bottomStripe != null,
        topOverlayKey: widget.topStripe == null ? null : _topOverlayKey,
        animatedOverlayKey:
            widget.animatedOverlay == null ? null : _animatedOverlayKey,
        animationType: widget.animationType,
      );

      if (path != null) {
        await shareVideo(path);
        widget.onShareComplete?.call(true);
      }
    } catch (e) {
      widget.onShareComplete?.call(false);

      throw e.toString();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// top overlay Overlay

        if (widget.topStripe != null)
          RepaintBoundary(
            key: _topOverlayKey,
            child: widget.topStripe!,
          ),

        Expanded(
          child: Stack(
            children: [
              /// Video  (Full Screen Cover)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                  ),
                  child: JarVideoPlayer(
                    url: widget.url,
                    controller: widget.controller,
                    reelsMode: widget.reelsMode,
                    autoPlay: widget.autoPlay,
                    loop: widget.loop,
                    videoRouteObserver: widget.videoRouteObserver,
                    onStatusChanged: (isLoading, progress) {
                      setState(() {
                        isVideoLoading = isLoading;
                        videoProgress = progress;
                        widget.onStatusChanged?.call(false, 0);
                      });
                    },
                    // aspectRatio: 9/16,
                  ),
                ),
              ),

              /// Bottom Overlay
              if (widget.bottomStripe != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RepaintBoundary(
                    key: _bottomOverlayKey,
                    child: widget.bottomStripe!,
                  ),
                ),
              if (widget.animatedOverlay != null && !isVideoLoading)
                RepaintBoundary(
                  key: _animatedOverlayKey,
                  child: AnimationWidget(
                    animatedOverlay: widget.animatedOverlay!,
                    animationType:
                        widget.animationType ?? OverlayAnimationType.none,
                  ),
                ),

              /// Buttons (center right)
              Positioned(
                right: widget.right,
                top: widget.top,
                bottom: widget.bottom,
                left: widget.left,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: widget.downloadIcon ??
                            Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 26,
                            ),
                        onTap: widget.onDownload ?? _handleDownload,
                        disabled: _isProcessing,
                        backgroundColor: widget.downloadBackgroundColor,
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        icon: widget.shareIcon ??
                            Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 26,
                            ),
                        onTap: widget.onShare ?? _handleShare,
                        disabled: _isProcessing,
                        backgroundColor: widget.shareBackgroundColor ??
                            widget.downloadBackgroundColor,
                      ),
                    ],
                  ),
                ),
              ),

              /// Loader
              if (_isProcessing)
                widget.shareDownloadProgressIndicator ??
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

///
/// this is for custom button of action button
///
class _ActionButton extends StatelessWidget {
  final Icon icon;
  final VoidCallback onTap;
  final bool disabled;
  final Color? backgroundColor;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
    this.backgroundColor,
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
            backgroundColor: backgroundColor ?? Colors.black54,
            child: icon,
          ),
        ),
      ),
    );
  }
}
