import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import '../../../../../../../../../Features/Other/crop.dart';
import '../../../../../../../../../Features/Widgets/image_services.dart';
import 'package:flutter/services.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<Uint8List> images;
  final Function(List<Uint8List>) onImagesChanged;
  final int maxImages;

  const ProductImageCarousel({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 5,
  });

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late PageController _pageController;
  late ScrollController _thumbnailController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _thumbnailController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  // Auto-scroll thumbnail to make selected image visible
  void _scrollToThumbnail(int index) {
    if (!_thumbnailController.hasClients) return;

    // Calculate the position to scroll to
    const thumbnailWidth = 84.0;
    const thumbnailMargin = 12.0;
    final itemWidth = thumbnailWidth + thumbnailMargin;

    // Get the visible area width
    final viewportWidth = _thumbnailController.position.viewportDimension;

    // Calculate the target scroll position to center the item
    double targetOffset = (index * itemWidth) - (viewportWidth / 2) + (thumbnailWidth / 2);

    // Clamp the offset to valid range
    targetOffset = targetOffset.clamp(
      0.0,
      _thumbnailController.position.maxScrollExtent,
    );

    // Animate to the target position
    _thumbnailController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _addImage() async {
    if (widget.images.length >= widget.maxImages) {
      if (mounted) {
        ToastManager.show(context: context, message: 'Maximum ${widget.maxImages} images allowed', type: ToastType.error);
      }
      return;
    }

    final remainingSlots = widget.maxImages - widget.images.length;
    final newImages = await ImagePickerService.pickMultipleImages(
      maxCount: remainingSlots,
    );

    if (newImages.isNotEmpty && mounted) {
      final List<Uint8List> updatedImages = List.from(widget.images);
      updatedImages.addAll(newImages);
      widget.onImagesChanged(updatedImages);

      if (updatedImages.length > _currentIndex) {
        final firstNewIndex = updatedImages.length - newImages.length;
        setState(() {
          _currentIndex = firstNewIndex;
        });
        _pageController.animateToPage(
          firstNewIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // Auto-scroll to the new image
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToThumbnail(firstNewIndex);
        });
      }
    }
  }

  // Fixed full screen viewer with proper navigation
  Future<void> _viewFullScreen() async {
    // Create a local state for the dialog
    int localIndex = _currentIndex;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: .92),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Focus(
            autofocus: true,
            onKeyEvent: (focusNode, event) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                if (localIndex > 0) {
                  setDialogState(() {
                    localIndex--;
                  });
                }
                return KeyEventResult.handled;
              }
              else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                if (localIndex < widget.images.length - 1) {
                  setDialogState(() {
                    localIndex++;
                  });
                }
                return KeyEventResult.handled;
              }
              else if (event.logicalKey == LogicalKeyboardKey.escape) {
                // Update main state when dialog closes
                if (localIndex != _currentIndex) {
                  setState(() {
                    _currentIndex = localIndex;
                  });
                  _pageController.animateToPage(
                    localIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  // Auto-scroll thumbnail
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToThumbnail(localIndex);
                  });
                }
                Navigator.of(dialogContext).pop();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  Container(
                    color: Colors.black.withValues(alpha: .92),
                    child: Stack(
                      children: [
                        // Main Image with Interactive Viewer
                        Center(
                          child: InteractiveViewer(
                            key: ValueKey(localIndex),
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(20),
                            child: Image.memory(
                              widget.images[localIndex],
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                            ),
                          ),
                        ),

                        // Gradient overlays
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: .7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: .7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Close Button
                        Positioned(
                          top: 48,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .3),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (localIndex != _currentIndex) {
                                    setState(() {
                                      _currentIndex = localIndex;
                                    });
                                    _pageController.animateToPage(
                                      localIndex,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _scrollToThumbnail(localIndex);
                                    });
                                  }
                                  Navigator.of(dialogContext).pop();
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Navigation buttons and counter
                        Positioned(
                          bottom: 30,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .6),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.images.length > 1)
                                    GestureDetector(
                                      onTap: () {
                                        if (localIndex > 0) {
                                          setDialogState(() {
                                            localIndex--;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: .1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_left,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '${localIndex + 1} / ${widget.images.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (widget.images.length > 1)
                                    GestureDetector(
                                      onTap: () {
                                        if (localIndex < widget.images.length - 1) {
                                          setDialogState(() {
                                            localIndex++;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: .1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Keyboard hint
                        Positioned(
                          bottom: 100,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.keyboard,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: .6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '←  →  arrows',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Image info
                        Positioned(
                          top: 48,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: .8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatBytes(widget.images[localIndex].length),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _editCurrentImage() async {
    final currentImage = widget.images[_currentIndex];
    final editedImage = await showImageCropper(
      context: context,
      imageBytes: currentImage,
      isEditing: true,
    );

    if (editedImage != null && mounted) {
      final List<Uint8List> updatedImages = List.from(widget.images);
      updatedImages[_currentIndex] = editedImage;
      widget.onImagesChanged(updatedImages);
    }
  }

  Future<void> _removeImageAtIndex(int index) async {
    if (widget.images.length <= 1) {
      final shouldRemove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirm),
          content: Text(AppLocalizations.of(context)!.removeLastImage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(AppLocalizations.of(context)!.remove),
            ),
          ],
        ),
      );
      if (shouldRemove != true) return;
    }

    final List<Uint8List> updatedImages = List.from(widget.images);
    updatedImages.removeAt(index);

    int newIndex = _currentIndex;
    if (newIndex >= updatedImages.length) {
      newIndex = updatedImages.length - 1;
    }
    if (newIndex < 0 && updatedImages.isNotEmpty) {
      newIndex = 0;
    }

    setState(() {
      _currentIndex = newIndex;
    });

    widget.onImagesChanged(updatedImages);

    if (updatedImages.isNotEmpty) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Auto-scroll after removal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToThumbnail(newIndex);
      });
    }
  }

  void _jumpToImage(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // Auto-scroll to the selected thumbnail
    _scrollToThumbnail(index);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasImages = widget.images.isNotEmpty;

    return Column(
      children: [
        // Main Image Display Area (Carousel)
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasImages
              ? Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  // Auto-scroll thumbnail when swiping
                  _scrollToThumbnail(index);
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: _viewFullScreen,
                    child: Image.memory(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64,
                                color: colorScheme.error,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tr.imageLoadError,
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              if (widget.images.length > 1) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: .5),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: .5),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],

              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fullscreen, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        "Full screen",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  tr.noImages,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Thumbnail Strip - Clean version without any scroll indicators
        if (hasImages) ...[
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: _thumbnailController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemBuilder: (context, index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () => _jumpToImage(index),
                  child: Container(
                    width: 84,
                    height: 84,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: .3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            widget.images[index],
                            fit: BoxFit.cover,
                            width: 84,
                            height: 84,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: colorScheme.errorContainer,
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: colorScheme.error,
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _removeImageAtIndex(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.black.withValues(alpha: .7),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action Buttons
        Row(
          spacing: 5,
          children: [
            Expanded(
              child: ZOutlineButton(
                onPressed: widget.images.length < widget.maxImages ? _addImage : null,
                icon: Icons.add_photo_alternate_outlined,
                label: Text(tr.addImage),
                isActive: widget.images.length < widget.maxImages,
              ),
            ),
            if (hasImages) ...[
              Expanded(
                child: ZOutlineButton(
                  onPressed: _editCurrentImage,
                  icon: Icons.crop,
                  label: Text(tr.edit),
                  isActive: true,
                ),
              ),
            ],
          ],
        ),

        if (!hasImages || widget.images.length < widget.maxImages)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${widget.images.length}/${widget.maxImages} ${tr.imagesAdded}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}