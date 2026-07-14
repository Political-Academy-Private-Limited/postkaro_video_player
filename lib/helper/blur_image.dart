import 'package:flutter/material.dart';

class BlurNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final double topLeft;
  final double topRight;
  final double bottomRight;
  final double bottomLeft;

  const BlurNetworkImage({
    super.key,
    required this.url,
    this.height = 100,
    this.width = 100,
    this.bottomLeft = 0,
    this.topRight = 0,
    this.topLeft = 0,
    this.bottomRight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomRight: Radius.circular(bottomRight),
        bottomLeft: Radius.circular(bottomLeft),
      ),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.cover,
      ),
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  final double curveDepth;

  BottomWaveClipper({required this.curveDepth});

  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height - curveDepth);

    path.quadraticBezierTo(
      size.width / 2,
      size.height + curveDepth,
      size.width,
      size.height - curveDepth,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant BottomWaveClipper oldClipper) {
    return oldClipper.curveDepth != curveDepth;
  }
}
