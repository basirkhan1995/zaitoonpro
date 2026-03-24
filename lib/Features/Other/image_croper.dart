import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:zaitoonpro/Features/Widgets/button.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';

/// Opens a crop dialog, lets the user crop manually,
/// then compresses the image to max 64 KB.

Future<Uint8List?> showCropDialog({
  required BuildContext context,
  required Uint8List imageBytes,
  String title = "Crop Image",
  double maxWidth = 600,
  double maxHeight = 500,
  int maxSizeKB = 64,
}) async {
  // Use the context synchronously to show the dialog
  final result = await showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return CropImageDialog(
        imageBytes: imageBytes,
        title: title,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        maxSizeKB: maxSizeKB,
      );
    },
  );

  return result;
}

class CropImageDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;
  final double maxWidth;
  final double maxHeight;
  final int maxSizeKB;

  const CropImageDialog({
    super.key,
    required this.imageBytes,
    this.title = "Crop Image",
    this.maxWidth = 600,
    this.maxHeight = 500,
    this.maxSizeKB = 64,
  });

  @override
  State<CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
  double cropLeft = 50;
  double cropTop = 50;
  double cropWidth = 200;
  double cropHeight = 200;
  double _imageWidth = 0;
  double _imageHeight = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _getImageDimensions();
  }

  void _getImageDimensions() {
    final image = img.decodeImage(widget.imageBytes);
    if (image != null) {
      setState(() {
        _imageWidth = image.width.toDouble();
        _imageHeight = image.height.toDouble();

        // Initialize crop area to cover most of the image
        cropWidth = _imageWidth * 0.7;
        cropHeight = _imageHeight * 0.7;
        cropLeft = (_imageWidth - cropWidth) / 2;
        cropTop = (_imageHeight - cropHeight) / 2;
      });
    }
  }

  Future<void> _processAndClose() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cropped = await _cropAndCompress(
        widget.imageBytes,
        cropLeft.toInt(),
        cropTop.toInt(),
        cropWidth.toInt(),
        cropHeight.toInt(),
        widget.maxSizeKB,
      );

      // Check if widget is still mounted before popping
      if (mounted) {
        Navigator.of(context).pop(cropped);
      }
    } catch (e) {
      // Handle error and only show snackbar if still mounted
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to crop image: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8)
        ),
        width: widget.maxWidth,
        height: widget.maxHeight,
        child: _imageWidth == 0
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          clipBehavior: Clip.none,
          children: [
            // Original image
            Positioned.fill(
              child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
            ),

            // Crop box (draggable + resizable)
            Positioned(
              left: cropLeft,
              top: cropTop,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    cropLeft = (cropLeft + details.delta.dx).clamp(0, _imageWidth - cropWidth);
                    cropTop = (cropTop + details.delta.dy).clamp(0, _imageHeight - cropHeight);
                  });
                },
                child: Container(
                  width: cropWidth,
                  height: cropHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    color: Colors.black.withValues(alpha: .3),
                  ),
                  child: Stack(
                    children: [
                      // Resize handle - bottom right
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              cropWidth = (cropWidth + details.delta.dx)
                                  .clamp(50, _imageWidth - cropLeft);
                              cropHeight = (cropHeight + details.delta.dy)
                                  .clamp(50, _imageHeight - cropTop);
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),

                      // Resize handle - top left
                      Positioned(
                        left: -10,
                        top: -10,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              final newWidth = cropWidth - details.delta.dx;
                              final newHeight = cropHeight - details.delta.dy;

                              if (cropLeft + details.delta.dx >= 0 &&
                                  cropTop + details.delta.dy >= 0 &&
                                  newWidth >= 50 &&
                                  newHeight >= 50) {
                                cropLeft += details.delta.dx;
                                cropTop += details.delta.dy;
                                cropWidth = newWidth;
                                cropHeight = newHeight;
                              }
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isProcessing)
          ZOutlineButton(
            width: 100,
            label: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ZButton(
          width: 100,
          onPressed: _isProcessing ? null : _processAndClose,
          label: _isProcessing
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Crop & Save"),
        ),
      ],
    );
  }
}

Future<Uint8List?> _cropAndCompress(
    Uint8List bytes,
    int left,
    int top,
    int width,
    int height,
    int maxSizeKB,
    ) async {
  try {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    // Ensure crop area is within image bounds
    final actualLeft = left.clamp(0, image.width - 1);
    final actualTop = top.clamp(0, image.height - 1);
    final actualWidth = width.clamp(1, image.width - actualLeft);
    final actualHeight = height.clamp(1, image.height - actualTop);

    // **Crop**
    img.Image cropped = img.copyCrop(
      image,
      x: actualLeft,
      y: actualTop,
      width: actualWidth,
      height: actualHeight,
    );

    // **Compress under specified KB**
    int quality = 95;
    Uint8List output;

    do {
      output = Uint8List.fromList(
        img.encodeJpg(cropped, quality: quality),
      );
      quality -= 5;
      if (quality < 10) break;
    } while (output.lengthInBytes > maxSizeKB * 1024);

    return output;
  } catch (e) {
    return null;
  }
}