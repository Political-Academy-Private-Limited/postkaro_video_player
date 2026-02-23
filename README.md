# jar_video_player

A modern, reels-ready, customizable network video player for Flutter.

`jar_video_player` is built for real-world performance. It provides
automatic lifecycle handling, route awareness, visibility-based playback
control, and optimized support for vertical reel-style feeds like
Instagram or TikTok.


https://github.com/user-attachments/assets/f1f8e44a-3425-4870-aa0e-35beab325ad8


------------------------------------------------------------------------

## ✨ Features
-   🎥 Network video playback (mp4, m3u8, etc.)
-   🔁 Reels mode (auto play/pause based on visibility)
-   🔄 Route-aware auto pause
-   📱 App lifecycle handling (background/foreground safety)
-   🎛 External controller support
-   ⚡ Optimized for `PageView` reels
-   🧠 Safe async initialization (prevents ghost audio issues)
-   🧹 Proper resource disposal to prevent memory leaks
-   🎨 Custom top & bottom overlay support
-   📥 Download video with overlays rendered
-   🎬 Animated overlay support with multiple animation types
-   🔊 Built-in Text-to-Speech (TTS) audio generation
-   🎵 Custom external audio merging support
-   📤 Built-in share functionality
-   🧩 Custom download & share callbacks
-   📊 Download/share status callbacks with progress tracking
-   🎚 Customizable overlay animation positions
-   🖼 Aspect ratio customization (9/16, 16/9, 1:1, etc.)
-   🔄 Auto-play & loop control options
-   🎨 Customizable download & share button styles
-   📂 Custom folder saving support
-   🎯 Configurable overlay control positioning
-   🧱 Even-dimension scaling for FFmpeg compatibility
-   🚀 Faststart MP4 optimization for smooth playback
-   🛡 Null-safe & production-ready architecture
------------------------------------------------------------------------

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

``` yaml
dependencies:
  jar_video_player: ^0.1.5
```

Then run:

``` bash
flutter pub get
```

------------------------------------------------------------------------
## 🚀 Some important permissions


``` xml


<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>


<!-- Internet (required for downloading video) -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>

<!-- Android 12 and below -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />


```


## 🚀 Overlay Jar Video Player

``` dart
import 'package:flutter/material.dart';
import 'package:jar_video_player/jar_video_player.dart';

final controller = JarVideoPlayerController();



///
// this must be true 
// for downloading and sharing the video with or without overlay 
// downloadWithOverlay: true,
///
JarVideoPlayerOverlay(
  url: videoUrl,
  aspectRatio: 9 / 16,
  reelsMode: true,

  /// Enable download with overlays
  downloadWithOverlay: true,

  /// 🔊 This will generate TTS and merge as audio
  ttsText: "Hello Sagar",

  /// Bottom overlay widget
  bottomStripe: Container(
    color: Colors.red,
    width: double.infinity,
    height: 70,
    alignment: Alignment.center,
    child: const Text(
      "Hello Sagar",
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  /// Optional top overlay
  // topStripe: Container(
  //   color: Colors.green,
  //   height: 50,
  //   alignment: Alignment.center,
  //   child: const Text("Hello leaders"),
  // ),

  /// Optional animation overlay
  // animatedOverlay: Image.asset("assets/anim.png"),
  // animationType: OverlayAnimationType.centerToBottom,

  /// Optional custom folder
  // folderName: "SanatanVideos",

  /// Optional callbacks
  // onDownloadComplete: (success) {
  //   print("Download completed: $success");
  // },

  // onShareComplete: (success) {
  //   print("Share completed: $success");
  // },
);
```

------------------------------------------------------------------------




```dart
///types of Overlay Animations
enum OverlayAnimationType {
  none, /// defauls to 'top left' 

  // Basic
  topToCenter,
  rightToCenter,
  leftToCenter,
  bottomToCenter,
  leftToRight,
  rightToLeft,

  // Diagonal
  diagonalTopLeftToBottomRight,
  diagonalTopRightToBottomLeft,
  diagonalBottomLeftToTopRight,
  diagonalBottomRightToTopLeft,
}

```

## 🎬 Reels Mode

Reels mode automatically plays the video when it becomes visible and
pauses it when it goes out of view.

``` dart
JarVideoPlayer(
  controller: controller,
  url: videoUrl,
  reelsMode: true,
);
```

### Recommended Usage with PageView

``` dart
PageView.builder(
  scrollDirection: Axis.vertical,
  itemCount: videoList.length,
  itemBuilder: (context, index) {
    final controller = JarVideoPlayerController();

    return JarVideoPlayer(
      controller: controller,
      url: videoList[index],
      reelsMode: true,
    );
  },
);
```

------------------------------------------------------------------------

## 🎛 Controller API

You can control playback manually using the controller:

``` dart
controller.play();
controller.pause();
controller.seekTo(Duration(seconds: 10));
controller.dispose();
```

------------------------------------------------------------------------

## 🔄 Lifecycle & Route Handling

`jar_video_player` automatically:

-   Pauses when navigating to a new route
-   Pauses when app goes to background
-   Resumes safely when returning
-   Prevents audio leaks during fast scroll

------------------------------------------------------------------------

## 🧩 Best Practices

-   Dispose controllers properly when no longer needed.
-   Use `reelsMode: true` inside `PageView` for best performance.
-   Avoid initializing multiple heavy videos simultaneously on low-end
    devices.

------------------------------------------------------------------------

## 📚 Example

A complete working example is available inside the `example/` folder of
this package.

------------------------------------------------------------------------

## 🛠 Requirements

-   Flutter 3.10+
-   Dart \>=3.0.0 \<4.0.0

------------------------------------------------------------------------

## 📝 License

MIT License

Copyright (c) 2026 Sagar

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish the Software.




