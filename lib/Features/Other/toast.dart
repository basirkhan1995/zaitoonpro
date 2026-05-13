import 'dart:math';
import 'package:flutter/material.dart';

class _OverlayContent extends StatelessWidget {
  final String? title;
  final String message;
  final Color color;
  final VoidCallback onDismiss;
  final int? durationInSeconds;
  final bool showProgressBar;

  const _OverlayContent({
    this.title,
    required this.message,
    required this.color,
    required this.onDismiss,
    this.durationInSeconds,
    this.showProgressBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ToastContainer(
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                  height: 50,
                  width: 50,
                  child: Image.asset("assets/images/zaitoonLogo.png")),
              const SizedBox(width: 10),

              // Content with better typography
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: .9),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    if (title != null) const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: .95),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Elegant dismiss button
              _DismissButton(
                onDismiss: onDismiss,
                color: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),

          // Animated progress bar for auto-dismiss
          if (showProgressBar && durationInSeconds != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _AnimatedProgressIndicator(
                durationInSeconds: durationInSeconds!,
                color: Theme.of(context).colorScheme.surface.withValues(alpha: .8),
                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: .2),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedIconContainer extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIconContainer({
    required this.icon,
    required this.color,
  });

  @override
  State<_AnimatedIconContainer> createState() => _AnimatedIconContainerState();
}

class _AnimatedIconContainerState extends State<_AnimatedIconContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..scaleByDouble(
              _scaleAnimation.value,
              _scaleAnimation.value,
              1.0,
              1.0,
            )
            ..rotateZ(_rotateAnimation.value),
          alignment: Alignment.center,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: .9),
                  widget.color.withValues(alpha: .7),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: .3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                widget.icon,
                color: Theme.of(context).colorScheme.surface,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToastContainer extends StatelessWidget {
  final Widget child;
  final Color color;

  const _ToastContainer({
    required this.child,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * -20),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: .95),
                  color.withValues(alpha: .85),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: .1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .2),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onDismiss;
  final Color color;

  const _DismissButton({
    required this.onDismiss,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: .1),
          ),
          child: Center(
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: color.withValues(alpha: .7),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressIndicator extends StatefulWidget {
  final int durationInSeconds;
  final Color color;
  final Color backgroundColor;

  const _AnimatedProgressIndicator({
    required this.durationInSeconds,
    required this.color,
    required this.backgroundColor,
  });

  @override
  State<_AnimatedProgressIndicator> createState() => _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<_AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.durationInSeconds),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(
            size: const Size(double.infinity, 3),
            painter: _WaveProgressPainter(
              progress: 1.0 - _controller.value,
              color: widget.color,
              backgroundColor: widget.backgroundColor,
            ),
          ),
        );
      },
    );
  }
}

class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _WaveProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.height / 2),
      ),
      backgroundPaint,
    );

    // Draw animated wave progress
    if (progress > 0) {
      final wavePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [color, color.withValues(alpha: .8)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final waveWidth = size.width * progress;
      final path = Path();

      // Create wave effect
      for (double x = 0; x < waveWidth; x++) {
        final y = sin(x * 0.1 + DateTime.now().millisecondsSinceEpoch * 0.002) * 1;
        if (x == 0) {
          path.moveTo(x, size.height / 2 + y);
        } else {
          path.lineTo(x, size.height / 2 + y);
        }
      }
      path.lineTo(waveWidth, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

// Enhanced Toast Manager with multiple positions
class ToastManager {
  static void show({
    required BuildContext context,
    String? title,
    required String message,
    required ToastType type,
    int durationInSeconds = 3,
    ToastPosition position = ToastPosition.top,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWrapper(
        title: title,
        message: message,
        type: type,
        durationInSeconds: durationInSeconds,
        position: position,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

enum ToastType {
  success,
  error,
  warning,
  info,
}

enum ToastPosition {
  top,
  bottom,
  center,
}

extension ToastTypeExtension on ToastType {
  Color get color {
    switch (this) {
      case ToastType.success:
        return const Color(0xFF10B981); // Emerald
      case ToastType.error:
        return const Color(0xFFEF4444); // Red
      case ToastType.warning:
        return const Color(0xFFF59E0B); // Amber
      case ToastType.info:
        return const Color(0xFF3B82F6); // Blue
    }
  }


}

class _ToastWrapper extends StatefulWidget {
  final String? title;
  final String message;
  final ToastType type;
  final int durationInSeconds;
  final ToastPosition position;

  const _ToastWrapper({
    this.title,
    required this.message,
    required this.type,
    required this.durationInSeconds,
    required this.position,
  });

  @override
  State<_ToastWrapper> createState() => _ToastWrapperState();
}

class _ToastWrapperState extends State<_ToastWrapper> with SingleTickerProviderStateMixin {
  late bool _visible;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _visible = true;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(Duration(seconds: widget.durationInSeconds), () {
      if (mounted && _visible) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_visible && mounted) {
      setState(() => _visible = false);
      _controller.reverse().then((_) {
        // Will be handled by onEnd callback
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getPositionOffset(Size size) {
    switch (widget.position) {
      case ToastPosition.top:
        return MediaQuery.of(context).padding.top + 24;
      case ToastPosition.bottom:
        return size.height - 120 - MediaQuery.of(context).padding.bottom;
      case ToastPosition.center:
        return size.height / 2 - 60;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      top: _getPositionOffset(size),
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: _animation,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _visible ? 1.0 : 0.0,
          onEnd: () {
            // Overlay entry removal will be handled by ToastManager
          },
          child: Material(
            color: Colors.transparent,
            child: _OverlayContent(
              title: widget.title,
              message: widget.message,
              color: widget.type.color,
              onDismiss: _dismiss,
              durationInSeconds: widget.durationInSeconds,
              showProgressBar: true,
            ),
          ),
        ),
      ),
    );
  }
}


class SimpleToastManager {
  static void show({
    required BuildContext context,
    String? title,
    required String message,
    required ToastType type,
    int durationInSeconds = 4,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 24,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * -20),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _OverlayContent(
              title: title,
              message: message,
              color: type.color,
              onDismiss: () {

              },
              durationInSeconds: durationInSeconds,
              showProgressBar: true,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss
    Future.delayed(Duration(seconds: durationInSeconds), () {
      overlayEntry.remove();
    });
  }
}