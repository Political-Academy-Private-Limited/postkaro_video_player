import 'package:flutter/material.dart';
import 'package:houseoftech_video_player/houseoftech_video_player.dart';

import 'home.dart';

void main() {
  runApp(const MyApp());
}

final videoRouteObserver = VideoRouteObserver();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorObservers: [videoRouteObserver], home: Home());
  }
}
