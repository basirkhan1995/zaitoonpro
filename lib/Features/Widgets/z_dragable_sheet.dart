import 'package:flutter/material.dart';

class ZDraggableSheet {
  static Future<T?> show<T>({
    required BuildContext context,

    /// 🔹 BODY BUILDER ONLY
    required Widget Function(
        BuildContext context,
        ScrollController scrollController,
        ) bodyBuilder,

    /// 🔹 HEADER
    String? title,
    Widget? leading,
    Widget? trailing,
    bool showCloseButton = true,
    bool showDragHandle = true,
    TextStyle? titleStyle,

    /// 🔹 SIZE CONTROL
    double initialChildSize = 0.6,
    double minChildSize = 0.35,
    double maxChildSize = 0.95,

    /// 🔹 ADAPTIVE HEIGHT
    bool adaptiveInitialSize = true,
    double estimatedContentHeight = 420,

    /// 🔹 STYLE
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),

    /// 🔹 BEHAVIOR
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final color = theme.colorScheme;

        final screenHeight = MediaQuery.of(context).size.height;

        final DraggableScrollableController sheetController =
        DraggableScrollableController();

        /// ⭐ Adaptive height
        double calculatedInitialSize = initialChildSize;

        if (adaptiveInitialSize) {
          calculatedInitialSize =
              (estimatedContentHeight / screenHeight).clamp(
                minChildSize,
                maxChildSize,
              );
        }

        Widget sheet = DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: calculatedInitialSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor ?? color.surface,
                borderRadius: borderRadius ??
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// 🔹 Drag Handle
                  if (showDragHandle)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (details) {
                        final delta = details.primaryDelta! / screenHeight;

                        double newSize = sheetController.size - delta;

                        newSize = newSize.clamp(minChildSize, maxChildSize);

                        sheetController.jumpTo(newSize);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                              Theme.of(context).colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),

                  /// 🔹 Header
                  if (title != null ||
                      showCloseButton ||
                      leading != null ||
                      trailing != null)
                    Row(
                      children: [
                        leading ?? const SizedBox(),

                        /// Title
                        Expanded(
                          child: title != null
                              ? Text(
                            title,
                            style: titleStyle ??
                                theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                              : const SizedBox(),
                        ),

                        /// trailing or close
                        trailing ??
                            (showCloseButton
                                ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => Navigator.pop(context),
                            )
                                : const SizedBox()),
                      ],
                    ),

                  /// 🔹 BODY
                  Expanded(
                    child: bodyBuilder(context, scrollController),
                  ),
                ],
              ),
            );
          },
        );

        /// 🔹 Keyboard safe
        if (useSafeArea) {
          sheet = SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: sheet,
            ),
          );
        }

        return sheet;
      },
    );
  }
}