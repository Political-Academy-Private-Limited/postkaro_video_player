import 'package:flutter/material.dart';

class BlurNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final double curveDepth; // how deep the curve is

  const BlurNetworkImage({
    super.key,
    required this.url,
    this.height = 100,
    this.width = 100,
    this.curveDepth = 30, // default curve depth
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BottomWaveClipper(curveDepth: curveDepth),
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
