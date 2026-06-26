import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loveinloop/src/domain/gift_project.dart';

class GiftImage extends StatelessWidget {
  const GiftImage({
    required this.photo,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    super.key,
  });

  final GiftPhoto photo;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = photo.isAsset
        ? Image.asset(
            photo.path,
            width: width,
            height: height,
            fit: BoxFit.cover,
          )
        : Image.file(
            File(photo.path),
            width: width,
            height: height,
            fit: BoxFit.cover,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}
