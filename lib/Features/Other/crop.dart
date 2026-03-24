import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

Future<Uint8List?> showImageCropper({
  required BuildContext context,
  required Uint8List imageBytes,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 700,
        height: 600,
        child: CustomCropper(imageBytes: imageBytes),
      ),
    ),
  );
}

class CustomCropper extends StatefulWidget {
  final Uint8List imageBytes;

  const CustomCropper({super.key, required this.imageBytes});

  @override
  State<CustomCropper> createState() => _CustomCropperState();
}

class _CustomCropperState extends State<CustomCropper> {
  ui.Image? decoded;

  /// Crop box rectangle in UI coordinates
  Rect cropRect = const Rect.fromLTWH(180, 120, 300, 300);

  /// Image displayed size and offset
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
                    /// IMAGE
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

                    /// SHADED OVERLAY
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _DarkenPainter(cropRect),
                        ),
                      ),
                    ),

                    /// CROP BOX
                    Positioned(
                      left: cropRect.left,
                      top: cropRect.top,
                      width: cropRect.width,
                      height: cropRect.height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                      ),
                    ),

                    /// Resize handles
                    ..._buildResizeHandles(),
                  ],
                ),
              );
            },
          ),
        ),

        /// BUTTONS
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ZOutlineButton(
                width: 110,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                label: Text(AppLocalizations.of(context)!.cancel),
              ),
              const SizedBox(width: 12),
              ZOutlineButton(
                width: 110,
                isActive: true,
                icon: Icons.crop,
                onPressed: () async {
                  // Capture NavigatorState safely
                  final navigator = Navigator.of(context);

                  // Crop & compress image
                  final bytes = await _cropAndCompressImage(maxBytes: 64 * 1024);

                  // Only pop if widget is still mounted
                  if (!mounted) return;
                  navigator.pop(bytes);
                },
                label:   Text(AppLocalizations.of(context)!.crop),
              ),
            ],
          ),
        )

      ],
    );
  }

  // ---------------------------------------------------------
  //  CROP + COMPRESS LOGIC
  // ---------------------------------------------------------

  Future<Uint8List> _cropAndCompressImage({int maxBytes = 64 * 1024}) async {
    // Map cropRect to image pixels
    final scaleX = decoded!.width / displayedWidth;
    final scaleY = decoded!.height / displayedHeight;

    final rect = Rect.fromLTWH(
      (cropRect.left - offsetX) * scaleX,
      (cropRect.top - offsetY) * scaleY,
      cropRect.width * scaleX,
      cropRect.height * scaleY,
    );

    Uint8List result = await _drawImageRect(decoded!, rect);

    // Compress if > maxBytes
    int width = rect.width.toInt();
    int height = rect.height.toInt();

    while (result.lengthInBytes > maxBytes && width > 50 && height > 50) {
      width = (width * 0.8).toInt();
      height = (height * 0.8).toInt();

      final resized = await _drawImageRect(decoded!, rect, targetWidth: width, targetHeight: height);
      result = resized;
    }

    return result;
  }

  Future<Uint8List> _drawImageRect(
      ui.Image image,
      Rect srcRect, {
        int? targetWidth,
        int? targetHeight,
      }) async {
    final w = targetWidth ?? srcRect.width.toInt();
    final h = targetHeight ?? srcRect.height.toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      image,
      srcRect,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint(),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ---------------------------------------------------------
  //  DRAG + RESIZE HANDLING
  // ---------------------------------------------------------

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
        rect = Rect.fromLTRB(rect.left + delta.dx, rect.top + delta.dy, rect.right, rect.bottom);
        break;
      case ResizeHandle.topRight:
        rect = Rect.fromLTRB(rect.left, rect.top + delta.dy, rect.right + delta.dx, rect.bottom);
        break;
      case ResizeHandle.bottomLeft:
        rect = Rect.fromLTRB(rect.left + delta.dx, rect.top, rect.right, rect.bottom + delta.dy);
        break;
      case ResizeHandle.bottomRight:
        rect = Rect.fromLTRB(rect.left, rect.top, rect.right + delta.dx, rect.bottom + delta.dy);
        break;
    }

    cropRect = rect;
  }

  ResizeHandle? _hitTestResizeHandle(Offset p) {
    const size = 18.0;
    if (Rect.fromCircle(center: cropRect.topLeft, radius: size).contains(p)) return ResizeHandle.topLeft;
    if (Rect.fromCircle(center: cropRect.topRight, radius: size).contains(p)) return ResizeHandle.topRight;
    if (Rect.fromCircle(center: cropRect.bottomLeft, radius: size).contains(p)) return ResizeHandle.bottomLeft;
    if (Rect.fromCircle(center: cropRect.bottomRight, radius: size).contains(p)) return ResizeHandle.bottomRight;
    return null;
  }

  List<Widget> _buildResizeHandles() {
   // const size = 16.0;
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
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  IMAGE SIZE CALCULATION
  // ---------------------------------------------------------

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

/// DARK OVERLAY EXCEPT CROP REGION
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
