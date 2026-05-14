import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Localizations/Bloc/localizations_bloc.dart';

class GenericMenuItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final String label;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double borderRadius;
  final double? fontSize;
  final bool isExpanded;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GenericMenuItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.fontSize,
    this.icon,
    required this.label,
    this.isExpanded = true,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
    this.borderRadius = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    this.margin = const EdgeInsets.symmetric(horizontal: 1),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
        splashColor: Colors.transparent,
        child: Stack(
          children: [

            /// Fluent Indicator
            Positioned.fill(
              child: Align(
                alignment:
                context.read<LocalizationBloc>().state.languageCode == "en"
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: isSelected ? 10 : 18,
                    end: isSelected ? 18 : 10,
                  ),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutExpo,
                  builder: (context, height, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 3 : 2,
                      height: isSelected ? height : 10,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// Item Content
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: padding,
              margin: margin,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .07)
                    : unselectedColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment:
                isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [

                  /// Icon
                  if (icon != null)
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      scale: isSelected ? 1.08 : 1,
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? selectedTextColor
                            : unselectedTextColor,
                      ),
                    ),

                  if (isExpanded && icon != null)
                    const SizedBox(width: 6),

                  /// Label
                  if (isExpanded)
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontSize: fontSize ?? 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? selectedTextColor
                              : unselectedTextColor,
                        ),
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
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
  }
}

class GenericMenuWithScreen<T> extends StatefulWidget {
  final double? menuWidth;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final List<MenuDefinition<T>> items;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double borderRadius;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// 🔹 External control for default expanded/collapsed state
  final bool isExpanded;

  /// 🔹 Optional header
  final Widget Function(bool isExpanded)? menuHeaderBuilder;

  /// 🔹 Optional footer
  final Widget Function(bool isExpanded)? menuFooterBuilder;

  /// 🔹 Widget to show when no items are available
  final Widget? emptyStateWidget;

  const GenericMenuWithScreen({
    super.key,
    this.menuWidth,
    required this.selectedValue,
    required this.onChanged,
    required this.items,
    this.menuHeaderBuilder,
    this.menuFooterBuilder,
    this.emptyStateWidget,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
    this.borderRadius = 3,
    this.fontSize,
    this.padding,
    this.margin,
    this.isExpanded = true,
  });

  @override
  State<GenericMenuWithScreen<T>> createState() =>
      _GenericMenuWithScreenState<T>();
}

class _GenericMenuWithScreenState<T> extends State<GenericMenuWithScreen<T>> {
  late double minScreenSize;
  late double maxScreenSize;

  late bool isMenuExpanded;

  @override
  void initState() {
    super.initState();
    minScreenSize = 60;
    maxScreenSize = widget.menuWidth ?? 165;

    isMenuExpanded = widget.isExpanded;
    _fixInvalidSelection();
  }

  @override
  void didUpdateWidget(GenericMenuWithScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fixInvalidSelection();
  }

  void _fixInvalidSelection() {
    // Don't try to fix if items is empty
    if (widget.items.isEmpty) return;

    // Check if current selectedValue exists in items
    final isValid = widget.items.any((item) => item.value == widget.selectedValue);

    if (!isValid) {
      // Current selection is invalid, use first available item
      final firstAvailableValue = widget.items.first.value;

      // Use addPostFrameCallback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(firstAvailableValue);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Handle empty items case - show empty state
    if (widget.items.isEmpty) {
      return Row(
        children: [
          /// Sidebar (collapsed or expanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isMenuExpanded ? maxScreenSize : minScreenSize,
            height: double.infinity,
            margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 3,
                  spreadRadius: 2,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: .03),
                ),
              ],
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              children: [
                /// Toggle arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: IconButton(
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          icon: Icon(isMenuExpanded
                              ? Icons.chevron_left
                              : Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              isMenuExpanded = !isMenuExpanded;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Header (if provided)
                if (widget.menuHeaderBuilder != null) ...[
                  widget.menuHeaderBuilder!(isMenuExpanded),
                  const SizedBox(height: 8),
                ],

                /// Empty state message
                Expanded(
                  child: Center(
                    child: widget.emptyStateWidget ??
                        (isMenuExpanded
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_open_rounded,
                              size: 32,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: .3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No menu items available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .5),
                              ),
                            ),
                          ],
                        )
                            : const SizedBox.shrink()),
                  ),
                ),

                /// Footer (if provided)
                if (widget.menuFooterBuilder != null)
                  widget.menuFooterBuilder!(isMenuExpanded),
              ],
            ),
          ),

          /// Empty content area
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .1),
                ),
                borderRadius: BorderRadius.circular(5),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Center(
                child: widget.emptyStateWidget ??
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No content available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your permissions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .4),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
      );
    }

    // 🟢 Handle case where selected value doesn't exist in items
    // Instead of throwing, show loading or return empty while we fix it
    final isValid = widget.items.any(
          (item) => item.value == widget.selectedValue,
    );

    if (!isValid) {
      // Trigger fix if not already attempted
      _fixInvalidSelection();

      // Show loading state while fixing
      return const Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 🟢 Safely get the selected item - we know it exists now
    final selectedItem = widget.items.firstWhere(
          (e) => e.value == widget.selectedValue,
      orElse: () => widget.items.first, // Fallback, though we already validated
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔷 Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isMenuExpanded ? maxScreenSize : minScreenSize,
              clipBehavior: Clip.hardEdge,
              height: double.infinity,
              margin: widget.margin ??
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3,
                    spreadRadius: 2,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: .03),
                  ),
                ],
                borderRadius: BorderRadius.circular(5),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2),
                child: Column(
                  children: [
                    /// Toggle arrow
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .06),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: IconButton(
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              icon: Icon(isMenuExpanded
                                  ? Icons.chevron_left
                                  : Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  isMenuExpanded = !isMenuExpanded;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Header
                    if (widget.menuHeaderBuilder != null) ...[
                      widget.menuHeaderBuilder!(isMenuExpanded),
                      const SizedBox(height: 8),
                    ],

                    /// Menu list
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: widget.items.map((item) {
                          return GenericMenuItem(
                            isSelected: item.value == widget.selectedValue,
                            onTap: () {
                              widget.onChanged(item.value);
                            },
                            label: item.label,
                            icon: item.icon,
                            fontSize: widget.fontSize,
                            isExpanded: isMenuExpanded,
                            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2.0, vertical: 3),
                            borderRadius: widget.borderRadius,
                            selectedColor: widget.selectedColor,
                            unselectedColor: widget.unselectedColor,
                            selectedTextColor: widget.selectedTextColor,
                            unselectedTextColor: widget.unselectedTextColor,
                          );
                        }).toList(),
                      ),
                    ),

                    /// Footer
                    if (widget.menuFooterBuilder != null)
                      widget.menuFooterBuilder!(isMenuExpanded),
                  ],
                ),
              ),
            ),

            /// 🔷 Main content
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                child: selectedItem.screen,
              ),
            ),
          ],
        );
      },
    );
  }
}

class MenuDefinition<T> {
  final T value;
  final String label;
  final Widget screen;
  final IconData? icon;

  MenuDefinition({
    required this.value,
    required this.label,
    required this.screen,
    this.icon,
  });
}