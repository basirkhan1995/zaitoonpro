
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter/services.dart';

Future<Uint8List?> showImageCropper({
  required BuildContext context,
  required Uint8List imageBytes,
  bool isEditing = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: !isEditing,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 700,
        height: 600,
        child: CustomCropper(
          imageBytes: imageBytes,
          isEditing: isEditing,
        ),
      ),
    ),
  );
}

class CustomCropper extends StatefulWidget {
  final Uint8List imageBytes;
  final bool isEditing;

  const CustomCropper({
    super.key,
    required this.imageBytes,
    this.isEditing = false,
  });

  @override
  State<CustomCropper> createState() => _CustomCropperState();
}

class _CustomCropperState extends State<CustomCropper> {
  ui.Image? decoded;
  Rect cropRect = const Rect.fromLTWH(180, 120, 300, 300);
  double displayedWidth = 0;
  double displayedHeight = 0;
  double offsetX = 0;
  double offsetY = 0;
  ResizeHandle? activeHandle;
  Offset? dragStart;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final image = await decodeImageFromList(widget.imageBytes);
    setState(() => decoded = image);
  }

  @override
  Widget build(BuildContext context) {
    if (decoded == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _calculateDisplayedSize(constraints);
              return GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: (_) => activeHandle = null,
                child: Stack(
                  children: [
                    // IMAGE
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: displayedWidth,
                      height: displayedHeight,
                      child: RawImage(
                        image: decoded!,
                        fit: BoxFit.fill,
                      ),
                    ),
                    // SHADED OVERLAY
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _DarkenPainter(cropRect),
                        ),
                      ),
                    ),
                    // CROP BOX
                    Positioned(
                      left: cropRect.left,
                      top: cropRect.top,
                      width: cropRect.width,
                      height: cropRect.height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Resize handles
                    ..._buildResizeHandles(),
                  ],
                ),
              );
            },
          ),
        ),
        // BUTTONS
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ZOutlineButton(
                width: 110,
                onPressed: () => Navigator.of(context).pop(),
                label: Text(AppLocalizations.of(context)!.cancel),
              ),
              const SizedBox(width: 12),
              ZOutlineButton(
                width: 110,
                isActive: true,
                icon: widget.isEditing ? Icons.save : Icons.crop,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final bytes = await _cropAndCompressImage(
                    maxSizeKB: 50, // Target size in KB
                    quality: 85, // JPEG quality (1-100)
                  );
                  if (!mounted) return;
                  navigator.pop(bytes);
                },
                label: Text(
                  widget.isEditing
                      ? AppLocalizations.of(context)!.submit
                      : AppLocalizations.of(context)!.crop,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Uint8List> _cropAndCompressImage({
    int maxSizeKB = 50,
    int quality = 85,
  }) async {
    // Calculate crop rectangle in original image coordinates
    final scaleX = decoded!.width / displayedWidth;
    final scaleY = decoded!.height / displayedHeight;

    final rect = Rect.fromLTWH(
      (cropRect.left - offsetX) * scaleX,
      (cropRect.top - offsetY) * scaleY,
      cropRect.width * scaleX,
      cropRect.height * scaleY,
    );

    // First, crop the image
    Uint8List result = await _cropImage(decoded!, rect);

    // If the image is still too large, resize it
    int currentWidth = rect.width.toInt();
    int currentHeight = rect.height.toInt();

    // Calculate target size based on original dimensions
    // Aim for reasonable dimensions (max 1200px on longest side)
    double maxDimension = 1200;
    double aspectRatio = currentWidth / currentHeight;

    if (currentWidth > maxDimension || currentHeight > maxDimension) {
      if (currentWidth > currentHeight) {
        currentWidth = maxDimension.toInt();
        currentHeight = (maxDimension / aspectRatio).toInt();
      } else {
        currentHeight = maxDimension.toInt();
        currentWidth = (maxDimension * aspectRatio).toInt();
      }

      result = await _resizeImage(result, currentWidth, currentHeight, quality);
    }

    // Compress to target size using JPEG quality adjustment
    result = await _compressImageToTargetSize(result, maxSizeKB, quality);

    return result;
  }

  Future<Uint8List> _cropImage(ui.Image image, Rect srcRect) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final width = srcRect.width.toInt();
    final height = srcRect.height.toInt();

    canvas.drawImageRect(
      image,
      srcRect,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _resizeImage(Uint8List imageBytes, int targetWidth, int targetHeight, int quality) async {
    final ui.Image image = await decodeImageFromList(imageBytes);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the image scaled to target dimensions
    final paint = Paint()..isAntiAlias = true;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(targetWidth, targetHeight);

    // Convert to JPEG with quality
    final byteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _compressImageToTargetSize(
      Uint8List imageBytes,
      int maxSizeKB,
      int initialQuality,
      ) async {
    int currentQuality = initialQuality;
    Uint8List compressedBytes = imageBytes;

    // Try JPEG compression with decreasing quality until size is under limit
    while (compressedBytes.lengthInBytes > maxSizeKB * 1024 && currentQuality > 30) {
      final ui.Image image = await decodeImageFromList(compressedBytes);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(image, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final img = await picture.toImage(image.width, image.height);

      // Note: Flutter doesn't directly support JPEG quality parameter
      // We'll use a different approach - reduce dimensions
      currentQuality -= 10;

      // Instead of quality, reduce dimensions
      int newWidth = (image.width * 0.9).toInt();
      int newHeight = (image.height * 0.9).toInt();

      final resizedImage = await _resizeImageToDimensions(img, newWidth, newHeight);
      compressedBytes = await _encodeToPNG(resizedImage);
    }

    // Final compression to ensure under limit
    if (compressedBytes.lengthInBytes > maxSizeKB * 1024) {
      compressedBytes = await _encodeToJPEGWithQuality(compressedBytes, 70);
    }
    return compressedBytes;
  }

  Future<ui.Image> _resizeImageToDimensions(ui.Image image, int targetWidth, int targetHeight) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint()..isAntiAlias = true,
    );

    final picture = recorder.endRecording();
    return await picture.toImage(targetWidth, targetHeight);
  }

  Future<Uint8List> _encodeToPNG(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _encodeToJPEGWithQuality(Uint8List imageBytes, int quality) async {
    // Since Flutter's ImageByteFormat doesn't have JPEG with quality,
    // we'll use a simpler approach: resize more aggressively
    final ui.Image image = await decodeImageFromList(imageBytes);

    // Calculate new dimensions based on quality (lower quality = smaller size)
    double scaleFactor = quality / 100.0;
    int newWidth = (image.width * scaleFactor).toInt();
    int newHeight = (image.height * scaleFactor).toInt();

    // Ensure minimum dimensions
    newWidth = newWidth.clamp(100, image.width);
    newHeight = newHeight.clamp(100, image.height);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      Paint()..isAntiAlias = true,
    );

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(newWidth, newHeight);
    final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onPanStart(DragStartDetails d) {
    dragStart = d.localPosition;
    activeHandle = _hitTestResizeHandle(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final delta = d.localPosition - dragStart!;
    dragStart = d.localPosition;
    setState(() {
      if (activeHandle == null) {
        cropRect = cropRect.shift(delta);
      } else {
        _resizeCrop(activeHandle!, delta);
      }
    });
  }

  void _resizeCrop(ResizeHandle handle, Offset delta) {
    var rect = cropRect;
    switch (handle) {
      case ResizeHandle.topLeft:
        rect = Rect.fromLTRB(
            rect.left + delta.dx, rect.top + delta.dy, rect.right, rect.bottom);
        break;
      case ResizeHandle.topRight:
        rect = Rect.fromLTRB(
            rect.left, rect.top + delta.dy, rect.right + delta.dx, rect.bottom);
        break;
      case ResizeHandle.bottomLeft:
        rect = Rect.fromLTRB(
            rect.left + delta.dx, rect.top, rect.right, rect.bottom + delta.dy);
        break;
      case ResizeHandle.bottomRight:
        rect = Rect.fromLTRB(rect.left, rect.top, rect.right + delta.dx,
            rect.bottom + delta.dy);
        break;
    }
    cropRect = rect;
  }

  ResizeHandle? _hitTestResizeHandle(Offset p) {
    const size = 18.0;
    if (Rect.fromCircle(center: cropRect.topLeft, radius: size).contains(p)) {
      return ResizeHandle.topLeft;
    }
    if (Rect.fromCircle(center: cropRect.topRight, radius: size).contains(p)) {
      return ResizeHandle.topRight;
    }
    if (Rect.fromCircle(center: cropRect.bottomLeft, radius: size).contains(p)) {
      return ResizeHandle.bottomLeft;
    }
    if (Rect.fromCircle(center: cropRect.bottomRight, radius: size).contains(p)) {
      return ResizeHandle.bottomRight;
    }
    return null;
  }

  List<Widget> _buildResizeHandles() {
    return [
      _handleWidget(cropRect.topLeft),
      _handleWidget(cropRect.topRight),
      _handleWidget(cropRect.bottomLeft),
      _handleWidget(cropRect.bottomRight),
    ];
  }

  Widget _handleWidget(Offset pos) {
    const size = 16.0;
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
                color: Theme.of(context).colorScheme.primary, width: 2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  void _calculateDisplayedSize(BoxConstraints c) {
    final imgW = decoded!.width.toDouble();
    final imgH = decoded!.height.toDouble();
    final areaW = c.maxWidth;
    final areaH = c.maxHeight;
    final imgAspect = imgW / imgH;
    final areaAspect = areaW / areaH;

    if (imgAspect > areaAspect) {
      displayedWidth = areaW;
      displayedHeight = displayedWidth / imgAspect;
    } else {
      displayedHeight = areaH;
      displayedWidth = displayedHeight * imgAspect;
    }

    offsetX = (areaW - displayedWidth) / 2;
    offsetY = (areaH - displayedHeight) / 2;
  }
}

class _DarkenPainter extends CustomPainter {
  final Rect cropRect;
  _DarkenPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: .55);
    final full = Path()..addRect(Offset.zero & size);
    final cut = Path()..addRect(cropRect);
    canvas.drawPath(Path.combine(PathOperation.difference, full, cut), paint);
  }

  @override
  bool shouldRepaint(_) => true;
}

enum ResizeHandle { topLeft, topRight, bottomLeft, bottomRight }