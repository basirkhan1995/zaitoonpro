import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zaitoonpro/Services/api_services.dart';

enum ShapeStyle { circle, roundedRectangle }

class ImageHelper {
  /// Full widget with optional camera overlay and separate tap handlers
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

    // Tap handlers
    VoidCallback? onCameraTap,
    VoidCallback? onImageTap,
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
        imageUrl: "${ApiServices.imageUrl}$imageName",
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

    /// ---------- Final widget with border and tap handling ----------
    return GestureDetector(
      onTap: onImageTap,
      child: Stack(
        children: [
          /// Outer border container
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

          /// Camera overlay with separate tap
          if (showCameraIcon)
            Positioned.fill(
              child: Align(
                alignment: cameraIconAlignment,
                child: GestureDetector(
                  onTap: onCameraTap,
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
            ),
        ],
      ),
    );
  }

  /// Helper method to show full-screen image viewer
  static Future<void> showImageViewer({
    required BuildContext context,
    required String? imageName,
    Uint8List? localImageBytes,
    String? heroTag,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full screen image
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black87,
                  child: Center(
                    child: Hero(
                      tag: heroTag ?? 'profile_image',
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: _buildFullScreenImage(
                          imageName: imageName,
                          localImageBytes: localImageBytes,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildFullScreenImage({required String? imageName, Uint8List? localImageBytes}) {
    if (localImageBytes != null) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.memory(
          localImageBytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (imageName == null || imageName.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 100,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'No Image Available',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(15),
        width: double.infinity,
        height: double.infinity,
        child: CachedNetworkImage(
          imageUrl: "${ApiServices.imageUrl}$imageName",
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, _) => Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          errorWidget: (_, _, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 100,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}