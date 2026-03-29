import 'package:flutter/material.dart';

/// A generic card widget for displaying information with avatar, title, subtitle,
/// status badge, and multiple info rows - with centered content layout.
class ZCard extends StatefulWidget {
  /// The image to display (can be network URL, asset path, or widget)
  final Widget? image;

  /// The main title text
  final String title;

  /// The subtitle text
  final String? subtitle;

  /// List of info items to display (icon + text)
  final List<InfoItem> infoItems;

  /// Status badge configuration
  final InfoStatus? status;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Whether the card is hoverable
  final bool hoverable;

  /// Border radius
  final double borderRadius;

  /// Padding inside the card
  final EdgeInsets padding;

  /// Whether to show divider between header and info items
  final bool showDivider;

  /// Custom builder for the image section
  final Widget Function(BuildContext context)? imageBuilder;

  /// Custom builder for the title section
  final Widget Function(BuildContext context)? titleBuilder;

  /// Custom builder for the info items section
  final Widget Function(BuildContext context)? infoItemsBuilder;

  const ZCard({
    super.key,
    this.image,
    required this.title,
    this.subtitle,
    this.infoItems = const [],
    this.status,
    this.onTap,
    this.hoverable = true,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.all(12),
    this.showDivider = true,
    this.imageBuilder,
    this.titleBuilder,
    this.infoItemsBuilder,
  });

  @override
  State<ZCard> createState() => _ZCardState();
}

/// Represents an info item (icon + text)
class InfoItem {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final TextStyle? textStyle;

  const InfoItem({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textStyle,
  });
}

/// Represents a status badge
class InfoStatus {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final TextStyle? labelStyle;

  const InfoStatus({
    required this.label,
    required this.color,
    this.backgroundColor,
    this.labelStyle,
  });
}

class _ZCardState extends State<ZCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: widget.hoverable
          ? (_) => setState(() => _isHovering = true)
          : null,
      onExit: widget.hoverable
          ? (_) => setState(() => _isHovering = false)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isHovering && widget.hoverable
                ? color.primary.withValues(alpha: .3)
                : color.outline.withValues(alpha: .25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovering && widget.hoverable
                  ? color.primary.withValues(alpha: .35)
                  : color.outline.withValues(alpha: .15),
              blurRadius: _isHovering ? 4 : 1,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: widget.onTap,
          child: Padding(
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Header (Image + Title + Status) - CENTERED
                _buildHeaderSection(context),

                if (widget.showDivider && widget.infoItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],

                /// Info Items - CENTERED
                if (widget.infoItems.isNotEmpty)
                  _buildInfoItemsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    if (widget.imageBuilder != null) {
      return widget.imageBuilder!(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Image at TOP (centered)
        if (widget.image != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.image!,
            ),
          ),
          const SizedBox(height: 10),
        ],

        /// Title and Status Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: widget.titleBuilder != null
                  ? widget.titleBuilder!(context)
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        /// Status Badge below title (centered)
        if (widget.status != null) ...[
          const SizedBox(height: 8),
          Center(
            child: _buildStatusBadge(widget.status!),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItemsSection(BuildContext context) {
    if (widget.infoItemsBuilder != null) {
      return widget.infoItemsBuilder!(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widget.infoItems
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _buildCenteredInfoRow(item, context),
      ))
          .toList(),
    );
  }

  Widget _buildStatusBadge(InfoStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.backgroundColor ?? status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: status.labelStyle ??
            TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
      ),
    );
  }

  Widget _buildCenteredInfoRow(InfoItem item, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.icon,
          size: 14,
          color: item.iconColor ?? Theme.of(context).hintColor,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            item.text,
            style: item.textStyle ?? Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}