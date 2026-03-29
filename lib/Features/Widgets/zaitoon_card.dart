import 'package:flutter/material.dart';

/// A specialized card widget for displaying individual/stakeholder information
/// with avatar image at top, name, email, gender badge, and contact details.
class ZaitoonCard extends StatefulWidget {
  final Widget? image;
  final String title;
  final String? subtitle;
  final List<ZaitoonInfoItem> infoItems;
  final ZaitoonStatus? status;
  final VoidCallback? onTap;
  final bool hoverable;
  final double borderRadius;
  final double cardWidth;
  final double cardHeight;

  const ZaitoonCard({
    super.key,
    this.image,
    required this.title,
    this.subtitle,
    this.infoItems = const [],
    this.status,
    this.onTap,
    this.hoverable = true,
    this.borderRadius = 12,
    this.cardWidth = 200,
    this.cardHeight = 220,
  });

  @override
  State<ZaitoonCard> createState() => _ZaitoonCardState();
}

class ZaitoonInfoItem {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final TextStyle? textStyle;

  const ZaitoonInfoItem({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textStyle,
  });
}

class ZaitoonStatus {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final TextStyle? labelStyle;

  const ZaitoonStatus({
    required this.label,
    required this.color,
    this.backgroundColor,
    this.labelStyle,
  });
}

class _ZaitoonCardState extends State<ZaitoonCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.cardWidth,
      height: widget.cardHeight,
      child: MouseRegion(
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isHovering && widget.hoverable
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovering && widget.hoverable
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: _isHovering ? 8 : 2,
                offset: Offset(0, _isHovering ? 4 : 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.image != null)
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 55,
                                height: 55,
                                child: widget.image,
                              ),
                            ),
                          ),
                        if (widget.image != null) const SizedBox(height: 8),
                        Center(
                          child: Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                          Center(
                            child: Text(
                              widget.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 6),
                        if (widget.infoItems.isNotEmpty)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        const SizedBox(height: 6),
                        if (widget.infoItems.isNotEmpty)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.infoItems
                                .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _buildCenteredInfoRow(item, context),
                            ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  if (widget.status != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _buildStatusBadge(widget.status!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ZaitoonStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.backgroundColor ?? status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: status.labelStyle ??
            TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
      ),
    );
  }

  Widget _buildCenteredInfoRow(ZaitoonInfoItem item, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.icon,
          size: 10,
          color: item.iconColor ?? Theme.of(context).hintColor,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            item.text,
            style: item.textStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}