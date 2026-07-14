import 'dart:math';
import 'package:example/test_class.dart';
import 'package:flutter/material.dart';
import 'package:houseoftech_video_player/houseoftech_video_player.dart';

import 'main.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final PageController _pageController = PageController();
  final Random _random = Random();
  late List<bool> isVideoPage;

  final List<String> videoUrls = <String>[
    "https://res.cloudinary.com/dlorfgn2x/video/upload/q_auto,f_auto/Sanatan/post/53293854424951926407",
    "http://res.cloudinary.com/dlorfgn2x/video/upload/q_auto,f_auto/Sanatan/post/54286548113597547617",
    "https://res.cloudinary.com/dlorfgn2x/video/upload/q_auto,f_auto/Sanatan/post/56949588480660426430",
    "https://res.cloudinary.com/dlorfgn2x/video/upload/q_auto,f_auto/Sanatan/post/63671731050165849607",
  ];

  @override
  void initState() {
    super.initState();

    /// Generate 10 random pages (true = video, false = image)
    isVideoPage = List.generate(20, (_) => _random.nextBool());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TestClass()),
          );
        },
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: isVideoPage.length,
        onPageChanged: (value) {
          if (value % 2 == 0) {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Text(
                      "Hello",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
        itemBuilder: (context, index) {
          if (isVideoPage[index]) {
            return _buildVideoPage(index);
          } else {
            return _buildImagePage();
          }
        },
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.black),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    "Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.next_plan_outlined),
                title: const Text("Go to Test Page"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TestClass()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPage(int index) {
    // final ctrl = HouseOfTechController();
    final videoUrl = videoUrls[index % videoUrls.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),

      child: HotVideoPlayerOverlay(
        url: videoUrl,
        aspectRatio: 9 / 16,
        reelsMode: true,
        downloadWithOverlay: true,
        isMute: true,
        videoLoader: Center(child: Text("place....")),

        videoRouteObserver: videoRouteObserver,
        onDownloadComplete: (success) {},
        topStripe: Container(
          color: Colors.green,
          width: double.infinity,
          height: 50,
          child: Text("Hello leaders", style: TextStyle(fontSize: 37)),
        ),

        /// these are for
        bottomStripe: Container(
          color: Colors.red,
          width: double.infinity,
          height: 70,
          child: Text("Hello House Of tech"),
        ),

        /// these is for animated overlay
        animationData: OverlayAnimationData(
          start: Offset(1, 1),
          end: Offset(.5, .5),
          duration: Duration(milliseconds: 5000),
        ),

        animatedOverlay: BlurNetworkImage(
          url:
              "https://as1.ftcdn.net/jpg/16/65/67/54/1000_F_1665675417_kxphTKeghxkmNfhJfx8PqQI2DevEnaG2.webp",
          curveDepth: 30,
          height: 120,
        ),

        ///if you want reel mode, controller is not necessary
        // controller: ctrl,
        ttsText:
            "बिना फल की आसक्ति के, अपने कर्तव्यों (काम) को समर्पण के साथ करना ही सच्चा कर्मयोग है।",
      ),
    );
  }

  Widget _buildImagePage() {
    return Image.network(
      "https://picsum.photos/600/900?random=${_random.nextInt(1000)}",
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
    );
  }
}
