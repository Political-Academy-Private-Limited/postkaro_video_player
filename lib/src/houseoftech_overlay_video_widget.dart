import 'package:flutter/material.dart';
import 'package:houseoftech_video_player/helper/animation_widget.dart';
import 'package:houseoftech_video_player/helper/utils.dart';
import 'package:houseoftech_video_player/helper/video_export_service.dart';
import 'package:media_store_plus/media_store_plus.dart';
import '../houseoftech_video_player.dart';

class HotVideoPlayerOverlay extends StatefulWidget {
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
  final HouseOfTechController? controller;

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

  /// Whether the video should be muted. Defaults to false.
  final bool isMute;

  /// Placeholder widget shown while the video is loading.
  final Widget? videoLoader;

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

  /// Custom overlay widgets and their positions.
  final Widget? overlayWidget;
  final Offset? overlayPosition;

  final Widget? overlayWidget1;
  final Offset? overlayPosition1;

  /// Animation data for the `animatedOverlay`.
  /// Defines starting/ending offsets and durations.
  final OverlayAnimationData? animationData;

  /// Custom progress indicator shown during video processing.
  /// Defaults to a centered `CircularProgressIndicator`.
  final Widget? shareDownloadProgressIndicator;

  ///download with custom overlays
  final bool downloadWithOverlay;

  /// Callback for video status changes (loading state and progress).
  final void Function(bool isLoading, double progress)? onStatusChanged;

  /// Callback for export progress (download/share).
  final void Function(double progress)? onExportProgress;

  /// Padding/Positioning for the action buttons (download/share).
  final double top;
  final double bottom;
  final double? left;

  /// Vertical space between the download and share buttons.
  final double spaceBwDownShare;

  /// Observer to automatically pause/play video based on route changes.
  final VideoRouteObserver? videoRouteObserver;

  /// The folder name where the downloaded video will be saved.
  final String? folderName;

  /// Text-to-speech text to be included in the exported video.
  final String? ttsText;

  /// This is for share text.
  final String? shareText;

  const HotVideoPlayerOverlay({
    super.key,
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

  @override
  State<HotVideoPlayerOverlay> createState() => _HotVideoPlayerOverlayState();
}

class _HotVideoPlayerOverlayState extends State<HotVideoPlayerOverlay> {
  static const _defaultAnimationData = OverlayAnimationData(
    startOffset: Offset(1, 0),
    endOffset: Offset(1, 0),
    duration: Duration(milliseconds: 2000),
    startDuration: Duration(milliseconds: 1000),
  );

  late final HouseOfTechController _controller;

  final GlobalKey _bottomOverlayKey = GlobalKey();
  final GlobalKey _topOverlayKey = GlobalKey();
  final GlobalKey _animatedOverlayKey = GlobalKey();
  final GlobalKey _overlayKey = GlobalKey();
  final GlobalKey _overlayKey1 = GlobalKey();

  bool _isProcessing = false;
  bool isVideoLoading = false;
  double videoProgress = 0;
  double _exportProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? HouseOfTechController();
  }

  @override
  void dispose() {
    // Only dispose if we created it internally
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Internal method to process video with overlays for download or share.
  Future<String?> _processVideoWithOverlay() async {
    setState(() {
      _exportProgress = 0;
    });
    return exportVideoWithOverlay(
      videoUrl: widget.url,
      overlayKey: widget.overlayWidget == null ? null : _overlayKey,
      overlayKey1: widget.overlayWidget1 == null ? null : _overlayKey1,
      overlayOffSet: widget.overlayPosition,
      overlayOffSet1: widget.overlayPosition1,
      bottomOverlayKey: widget.bottomStripe == null ? null : _bottomOverlayKey,
      downloadWithOverlay: widget.downloadWithOverlay,
      topOverlayKey: widget.topStripe == null ? null : _topOverlayKey,
      animatedOverlayKey:
          widget.animatedOverlay == null ? null : _animatedOverlayKey,
      animationType: widget.animationData ?? _defaultAnimationData,
      ttsText: widget.ttsText,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _exportProgress = progress;
          });
          widget.onExportProgress?.call(progress);
        }
      },
    );
  }

  /// Handles the video download process.
  Future<void> _handleDownload() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final path = await _processVideoWithOverlay();

      if (path != null) {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = widget.folderName ?? "Overlay Video";

        await MediaStore().saveFile(
          tempFilePath: path,
          dirType: DirType.video,
          dirName: DirName.movies,
        );

        widget.onDownloadComplete?.call(true);
      } else {
        widget.onDownloadComplete?.call(false);
      }
    } catch (e) {
      widget.onDownloadComplete?.call(false);
      debugPrint("Download error: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Handles the video sharing process.
  Future<void> _handleShare() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final path = await _processVideoWithOverlay();

      if (path != null) {
        await shareVideo(path, widget.shareText);
        widget.onShareComplete?.call(true);
      } else {
        widget.onShareComplete?.call(false);
      }
    } catch (e) {
      widget.onShareComplete?.call(false);
      debugPrint("Share error: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.topStripe != null)
          RepaintBoundary(
            key: _topOverlayKey,
            child: widget.topStripe!,
          ),
        Expanded(
          child: ClipRRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: HouseOfTechVideoPlayer(
                    url: widget.url,
                    controller: _controller,
                    reelsMode: widget.reelsMode,
                    autoPlay: widget.autoPlay,
                    loop: widget.loop,
                    isMute: widget.isMute,
                    videoLoader: widget.videoLoader,
                    videoRouteObserver: widget.videoRouteObserver,
                    onStatusChanged: (isLoading, progress) {
                      setState(() {
                        isVideoLoading = isLoading;
                        videoProgress = progress;
                        widget.onStatusChanged?.call(isLoading, progress);
                      });
                    },
                  ),
                ),
                if (widget.bottomStripe != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: RepaintBoundary(
                      key: _bottomOverlayKey,
                      child: widget.bottomStripe!,
                    ),
                  ),
                if (widget.animatedOverlay != null && !isVideoLoading) ...[
                  AnimationWidget(
                    animationType:
                        widget.animationData ?? _defaultAnimationData,
                    animatedOverlay: widget.animatedOverlay!,
                    controller: _controller,
                  ),
                  Transform.translate(
                    offset: const Offset(-100000, -100000),
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        key: _animatedOverlayKey,
                        child: AnimationWidget(
                          animationType: OverlayAnimationData(
                            startOffset:
                                (widget.animationData ?? _defaultAnimationData)
                                    .endOffset,
                            endOffset:
                                (widget.animationData ?? _defaultAnimationData)
                                    .endOffset,
                            duration: Duration.zero,
                            startDuration: Duration.zero,
                          ),
                          animatedOverlay: widget.animatedOverlay!,
                        ),
                      ),
                    ),
                  ),
                ],
                if (widget.overlayWidget != null && !isVideoLoading)
                  Positioned.fill(
                    child: RepaintBoundary(
                      key: _overlayKey,
                      child: AnimationWidget(
                        animationType: OverlayAnimationData(
                          startOffset: widget.overlayPosition ?? Offset.zero,
                          endOffset: widget.overlayPosition ?? Offset.zero,
                          duration: Duration.zero,
                          startDuration: Duration.zero,
                        ),
                        animatedOverlay: widget.overlayWidget!,
                      ),
                    ),
                  ),
                if (widget.overlayWidget1 != null && !isVideoLoading)
                  Positioned.fill(
                    child: RepaintBoundary(
                      key: _overlayKey1,
                      child: AnimationWidget(
                        animationType: OverlayAnimationData(
                          startOffset: widget.overlayPosition1 ?? Offset.zero,
                          endOffset: widget.overlayPosition1 ?? Offset.zero,
                          duration: Duration.zero,
                          startDuration: Duration.zero,
                        ),
                        animatedOverlay: widget.overlayWidget1!,
                      ),
                    ),
                  ),
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
                              const Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 26,
                              ),
                          onTap: widget.onDownload ?? _handleDownload,
                          disabled: _isProcessing,
                          backgroundColor: widget.downloadBackgroundColor,
                        ),
                        SizedBox(height: widget.spaceBwDownShare),
                        _ActionButton(
                          icon: widget.shareIcon ??
                              const Icon(
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
                if (_isProcessing)
                  widget.shareDownloadProgressIndicator ??
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _exportProgress > 0
                                    ? _exportProgress
                                    : null,
                                strokeWidth: 4,

                                backgroundColor: Colors.white24, // Track color
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue, // Progress color
                                ),
                              ),
                              Text(
                                _exportProgress > 0
                                    ? "${(_exportProgress * 100).toInt()}%"
                                    : "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
              ],
            ),
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
