import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum ShapeStyle { circle, roundedRectangle }

class ImageHelper {
  static const String baseUrl = "http://52.21.3.100/images/personal/";

  /// Full widget with optional camera overlay
  static Widget stakeholderProfile({
    required String? imageName,
    Uint8List? localImageBytes,

    // Size
    double size = 80,

    // Image Fit
    BoxFit fit = BoxFit.cover,

    // Placeholders / errors
    Color placeholderColor = const Color.fromRGBO(128, 128, 128, 0.2),
    Color errorColor = Colors.red,
    IconData placeholderIcon = Icons.person,
    IconData errorIcon = Icons.error,

    // Shape
    ShapeStyle shapeStyle = ShapeStyle.circle,
    double borderRadius = 5,
    BoxBorder? border,

    // Camera icon
    bool showCameraIcon = false,
    IconData cameraIcon = Icons.camera_alt,
    double cameraIconSize = 20,
    Color cameraIconBackground = Colors.black54,
    Color cameraIconColor = Colors.white,
    Alignment cameraIconAlignment = Alignment.bottomRight,
  }) {
    /// ---------- Build main image ----------
    Widget mainImage;

    if (localImageBytes != null) {
      mainImage = Image.memory(localImageBytes, fit: fit);
    } else if (imageName == null || imageName.isEmpty) {
      mainImage = Container(
        color: placeholderColor,
        child: Icon(
          placeholderIcon,
          size: size * 0.5,
          color: Colors.white,
        ),
      );
    } else {
      mainImage = CachedNetworkImage(
        imageUrl: "$baseUrl$imageName",
        fit: fit,
        placeholder: (_, _) => Center(
          child: SizedBox(
            width: size * 0.35,
            height: size * 0.35,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: errorColor,
          child: Icon(errorIcon, size: size * 0.5, color: Colors.white),
        ),
      );
    }

    /// ---------- Shape-based clipping ----------
    Widget clippedImage = ClipRRect(
      borderRadius: shapeStyle == ShapeStyle.circle
          ? BorderRadius.circular(size)
          : BorderRadius.circular(borderRadius),
      child: mainImage,
    );

    /// ---------- Final widget with border on top ----------
    return Stack(
      children: [
        /// Outer border container (WILL be visible)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: shapeStyle == ShapeStyle.circle
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: shapeStyle == ShapeStyle.circle
                ? null
                : BorderRadius.circular(borderRadius),
            border: border,
          ),
          clipBehavior: Clip.none,
          child: clippedImage,
        ),

        /// Camera overlay
        if (showCameraIcon)
          Positioned.fill(
            child: Align(
              alignment: cameraIconAlignment,
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cameraIconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cameraIcon,
                  size: cameraIconSize,
                  color: cameraIconColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
