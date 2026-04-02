import 'package:flutter/material.dart';

class ZCover extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? shadowColor;
  final double? radius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ZCover({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.radius,
    this.padding,
    this.margin,
  });

  bool _isChildEmpty() {
    if (child is Text) {
      final text = (child as Text).data ?? '';
      return text.trim().isEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isChildEmpty()) {
      return const SizedBox();
    }

    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Theme.of(context).colorScheme.surface,
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(radius ?? 3),
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .05),
      ),
      child: child,
    );
  }
}
