import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';

/// ------------------------------------------------------------
///  Z TAB STYLE OPTIONS
/// ------------------------------------------------------------
enum ZTabStyle { rounded, underline }

/// ------------------------------------------------------------
///  Z TAB ITEM MODEL
/// ------------------------------------------------------------
class ZTabItem<T> {
  final T value;
  final String label;
  final Widget screen;
  final IconData? icon;

  ZTabItem({
    required this.value,
    required this.label,
    required this.screen,
    this.icon,
  });
}

/// ------------------------------------------------------------
///  Z TAB CONTAINER (Unified Layout)
/// ------------------------------------------------------------
class ZTabContainer<T> extends StatefulWidget {
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final List<ZTabItem<T>> tabs;
  final bool closeButton;

  final String? title;
  final IconData? icon;
  final String? description;
  final VoidCallback? onBack;

  final ZTabStyle style;

  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry tabBarPadding;
  final MainAxisAlignment tabAlignment;
  final Color tabContainerColor;

  const ZTabContainer({
    super.key,
    this.closeButton = false,
    required this.selectedValue,
    required this.onChanged,
    required this.tabs,

    this.title,
    this.description,
    this.icon,
    this.onBack,

    this.style = ZTabStyle.rounded,

    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,

    this.borderRadius = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    this.margin = const EdgeInsets.symmetric(horizontal: 0),
    this.tabBarPadding = const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    this.tabAlignment = MainAxisAlignment.start,
    this.tabContainerColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ZTabContainer<T>> createState() => _ZTabContainerState<T>();
}

class _ZTabContainerState<T> extends State<ZTabContainer<T>> {
  bool _fixAttempted = false;

  @override
  void initState() {
    super.initState();
    _validateAndFixSelectedValue();
  }

  @override
  void didUpdateWidget(ZTabContainer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs != widget.tabs ||
        oldWidget.selectedValue != widget.selectedValue) {
      _fixAttempted = false;
      _validateAndFixSelectedValue();
    }
  }

  void _validateAndFixSelectedValue() {
    if (_fixAttempted) return;

    if (widget.tabs.isEmpty) {
      _fixAttempted = true;
      return;
    }

    final isValid = widget.tabs.any((tab) => tab.value == widget.selectedValue);

    if (!isValid) {
      _fixAttempted = true;
      final firstAvailableValue = widget.tabs.first.value;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(firstAvailableValue);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty tabs case
    if (widget.tabs.isEmpty) {
      return Center(
        child: Text(
          'No tabs available',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
          ),
        ),
      );
    }

    // Check if selected value exists in tabs
    final bool isSelectedValid = widget.tabs.any(
            (tab) => tab.value == widget.selectedValue
    );

    // If selected value doesn't exist, return SizedBox.shrink()
    if (!isSelectedValid) {
      if (!_fixAttempted) {
        _validateAndFixSelectedValue();
      }
      return const SizedBox.shrink();
    }

    // Safely get the selected tab - we know it exists now
    final selectedTab = widget.tabs.firstWhere(
          (e) => e.value == widget.selectedValue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---------------- Header + Tabs
        Container(
          width: double.infinity,
          margin: widget.margin,
          padding: widget.tabBarPadding,
          decoration: BoxDecoration(
            color: widget.tabContainerColor,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5)
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------------- Title + Back
              Row(
                children: [
                  // LEFT SIDE — takes remaining space
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.onBack != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            onPressed: widget.onBack,
                            padding: EdgeInsets.zero,
                          ),

                        if (widget.onBack != null) const SizedBox(width: 5),

                        if (widget.title != null)...[
                          Row(
                            children: [
                              if (widget.icon != null) Icon(widget.icon),
                              if (widget.icon != null) const SizedBox(width: 5),
                              Text(
                                widget.title!,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.scaledFont(0.04)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),

                  // RIGHT SIDE — close icon
                  if(widget.closeButton)
                    InkWell(
                        onTap: ()=> Navigator.of(context).pop(),
                        child: Icon(Icons.close)),
                ],
              ),
              /// ---------------- Optional Description
              if (widget.description != null) ...[
                Text(
                  widget.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: context.scaledFont(0.007)
                  ),
                ),
                const SizedBox(height: 10),
              ],

              /// ---------------- Tabs Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: widget.tabAlignment,
                  children: _buildZTabs(context),
                ),
              ),
            ],
          ),
        ),

        /// ---------------- Body
        Expanded(child: selectedTab.screen),
      ],
    );
  }

  /// ------------------------------------------------------------
  ///  BUILD TABS (Renamed to avoid conflicts)
  /// ------------------------------------------------------------
  List<Widget> _buildZTabs(BuildContext context) {
    switch (widget.style) {
      case ZTabStyle.rounded:
        return widget.tabs.map((tab) => _ZRoundedTab<T>(
          tab: tab,
          isSelected: tab.value == widget.selectedValue,
          onTap: () => widget.onChanged(tab.value),
          selectedColor: widget.selectedColor,
          unselectedColor: widget.unselectedColor,
          selectedTextColor: widget.selectedTextColor,
          unselectedTextColor: widget.unselectedTextColor,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
        )).toList();

      case ZTabStyle.underline:
        return widget.tabs.map((tab) => _ZUnderlineTab<T>(
          tab: tab,
          isSelected: tab.value == widget.selectedValue,
          onTap: () => widget.onChanged(tab.value),
          activeColor: widget.selectedColor,
          inactiveColor: widget.unselectedTextColor,
        )).toList();
    }
  }
}

/// ------------------------------------------------------------
///  ROUNDED TAB ITEM (Renamed)
/// ------------------------------------------------------------
class _ZRoundedTab<T> extends StatelessWidget {
  final ZTabItem<T> tab;
  final bool isSelected;
  final VoidCallback onTap;

  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const _ZRoundedTab({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.borderRadius,
    required this.padding,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          border: Border.all(
            color: isSelected
                ? selectedColor
                : Theme.of(context).colorScheme.outline.withValues(alpha: .3),
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            if (tab.icon != null)
              Icon(
                tab.icon,
                size: context.scaledFont(0.011),
                color: isSelected ? selectedTextColor : unselectedTextColor,
              ),
            if (tab.icon != null) const SizedBox(width: 5),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: context.scaledFont(0.010),
                color: isSelected ? selectedTextColor : unselectedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  UNDERLINE TAB ITEM (Renamed)
/// ------------------------------------------------------------
class _ZUnderlineTab<T> extends StatelessWidget {
  final ZTabItem<T> tab;
  final bool isSelected;
  final VoidCallback onTap;

  final Color activeColor;
  final Color inactiveColor;

  const _ZUnderlineTab({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withValues(alpha: .1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? activeColor : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (tab.icon != null)
              Icon(
                tab.icon,
                size: context.scaledFont(0.011),
                color: isSelected ? activeColor : inactiveColor,
              ),
            if (tab.icon != null) const SizedBox(width: 5),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: context.scaledFont(0.010),
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}