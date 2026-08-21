import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class HouseOfTechController extends ChangeNotifier {
  ///this is the Video Controller.
  VideoPlayerController? _videoController;

  VideoPlayerController? get videoController => _videoController;

  bool get isInitialized => _videoController?.value.isInitialized ?? false;

  bool get isPlaying => _videoController?.value.isPlaying ?? false;

  Duration get position => _videoController?.value.position ?? Duration.zero;

  Duration get duration => _videoController?.value.duration ?? Duration.zero;

  ///  Custom cache manager (optional but recommended)
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'HouseOfTechVideoCache',
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 7,
    ),
  );

  bool _isDisposed = false;

  Future<void> initialize(
    String url, {
    bool autoPlay = false,
    bool loop = false,
    bool isMute = false,
  }) async {
    /// Dispose old controller if exists
    await disposeVideo();
    if (_isDisposed) return;

    try {
      /// Get cached file (downloads only first time)
      final File file = await _cacheManager.getSingleFile(url);

      ///  Use local file instead of network
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      await _videoController!.setLooping(loop);

      if (isMute) {
        await _videoController!.setVolume(0);
      }

      if (autoPlay) {
        await _videoController!.play();
      }
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      /// fallback to network if cache fails
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      if (isMute) {
        await _videoController!.setVolume(0);
      }

      await _videoController!.initialize();
      await _videoController!.setLooping(loop);

      if (autoPlay) {
        await _videoController!.play();
      }
      if (!_isDisposed) notifyListeners();
    }
  }

  ///for playing the video
  Future<void> play() async {
    if (_videoController == null) return;
    await _videoController!.play();
  }

  ///for pausing the video
  Future<void> pause() async {
    if (_videoController == null) return;
    await _videoController!.pause();
  }

  ///for seeking to custom duration or position in the video
  Future<void> seekTo(Duration position) async {
    if (_videoController == null) return;
    await _videoController!.seekTo(position);
  }

  Future<void> disposeVideo() async {
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      await controller.dispose();
    }
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    final controller = _videoController;
    _videoController = null;
    controller?.dispose();
    super.dispose();
  }
}
