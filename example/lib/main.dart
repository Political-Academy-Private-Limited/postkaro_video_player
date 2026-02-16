import 'package:flutter/material.dart';
import 'package:jar_video_player/jar_video_player.dart';

import 'home.dart';

void main() {
  runApp(const MyApp());
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorObservers: [routeObserver], home: Home());
  }
}
