import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';

class GenericTabItem extends StatelessWidget {
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
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GenericTabItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.fontSize,
    this.icon,
    required this.label,
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
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        curve: Curves.easeInExpo,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : unselectedColor,
            border: Border.all(
              color: isSelected ? selectedColor : selectedColor.withValues(alpha: .2),
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: context.scaledFont(0.011),
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
              if (icon != null) const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.scaledFont(0.009),
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GenericTab<T> extends StatelessWidget {
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final List<TabDefinition<T>> tabs;

  final String? title;
  final String? description;
  final VoidCallback? onBack;

  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double borderRadius;
  final double? fontSize;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry tabBarPadding;
  final MainAxisAlignment tabAlignment;
  final Color tabContainerColor;

  const GenericTab({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    required this.tabs,
    this.title,
    this.description,
    this.onBack,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
    this.borderRadius = 3,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    this.margin = const EdgeInsets.symmetric(horizontal: 3),
    this.tabBarPadding = const EdgeInsets.symmetric(horizontal: 4,vertical: 5),
    this.tabAlignment = MainAxisAlignment.start,
    this.tabContainerColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    final selectedTab = tabs.firstWhere((e) => e.value == selectedValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Container wrapping title, description, and tab bar
        Container(
          width: double.infinity,
          padding: tabBarPadding,
          decoration: BoxDecoration(
            color: tabContainerColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,size: 18),
                        onPressed: onBack,
                        padding: EdgeInsets.zero,
                      ),
                    if(onBack !=null)
                      SizedBox(width: 5),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
              if (description != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    description!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              /// 🔹 Tab bar row
              Row(
                mainAxisAlignment: tabAlignment,
                children: tabs.map((tab) {
                  return GenericTabItem(
                    isSelected: tab.value == selectedValue,
                    onTap: () => onChanged(tab.value),
                    label: tab.label,
                    icon: tab.icon,
                    fontSize: fontSize,
                    padding: padding,
                    margin: margin,
                    borderRadius: borderRadius,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    selectedTextColor: selectedTextColor,
                    unselectedTextColor: unselectedTextColor,
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        /// 🔹 Screen content
        Expanded(child: selectedTab.screen),
      ],
    );
  }
}

class TabDefinition<T> {
  final T value;
  final String label;
  final Widget screen;
  final IconData? icon;

  TabDefinition({
    required this.value,
    required this.label,
    required this.screen,
    this.icon,
  });
}
