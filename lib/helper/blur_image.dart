import 'package:cached_network_image/cached_network_image.dart';
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
      child: CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
