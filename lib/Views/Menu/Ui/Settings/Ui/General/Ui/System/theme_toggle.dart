import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' show Platform;
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../../Themes/Bloc/themes_bloc.dart';


class ThemeSelectorWidget extends StatelessWidget {
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String title;
  final ThemeSelectorStyle style;
  final bool usePlatformDefault;

  const ThemeSelectorWidget({
    super.key,
    this.padding,
    this.margin,
    this.width,
    this.title = "",
    this.style = ThemeSelectorStyle.toggle,
    this.usePlatformDefault = true,
  });

  @override
  Widget build(BuildContext context) {
    if (usePlatformDefault) {
      // Automatically choose style based on platform
      final isDesktop = Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS;
      final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

      // Use dropdown for desktop/tablet, toggle for mobile
      final selectedStyle = (isDesktop || isTablet)
          ? ThemeSelectorStyle.dropdown
          : ThemeSelectorStyle.toggle;

      return _buildSelector(context, selectedStyle);
    }

    return _buildSelector(context, style);
  }

  Widget _buildSelector(BuildContext context, ThemeSelectorStyle style) {
    switch (style) {
      case ThemeSelectorStyle.dropdown:
        return ThemeDropdownSelector(
          width: width,
          padding: padding,
          margin: margin,
          title: title,
        );
      case ThemeSelectorStyle.toggle:
        return ThemeToggleSelector(
          width: width,
          padding: padding,
          margin: margin,
          title: title,
        );
      case ThemeSelectorStyle.segmented:
        return AndroidStyleThemeSelector(
          width: width,
          padding: padding,
          margin: margin,
          title: title,
        );
    }
  }
}

enum ThemeSelectorStyle {
  dropdown,
  toggle,
  segmented,
}

// Your original dropdown (fixed warnings)
class ThemeDropdownSelector extends StatefulWidget {
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final String title;

  const ThemeDropdownSelector({
    super.key,
    this.padding,
    this.margin,
    this.radius = 4,
    this.width,
    this.title = "",
  });

  @override
  State<ThemeDropdownSelector> createState() => _ThemeDropdownSelectorState();
}

class _ThemeDropdownSelectorState extends State<ThemeDropdownSelector> {
  bool _isOpen = false;
  late OverlayEntry _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _themeModes = [
    {'mode': 'system', 'icon': Icons.settings},
    {'mode': 'light', 'icon': Icons.light_mode},
    {'mode': 'dark', 'icon': Icons.dark_mode},
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _getThemeLabel(BuildContext context, String mode) {
    switch (mode) {
      case 'system':
        return AppLocalizations.of(context)!.systemMode;
      case 'light':
        return AppLocalizations.of(context)!.lightMode;
      case 'dark':
        return AppLocalizations.of(context)!.darkMode;
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeBloc>();
    final currentTheme = themeCubit.state.name.toLowerCase();
    final color = Theme.of(context).colorScheme;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (!hasFocus && _isOpen) {
          _overlayEntry.remove();
          setState(() {
            _isOpen = false;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          if (_isOpen) {
            _overlayEntry.remove();
          } else {
            _overlayEntry = _createOverlayEntry(context);
            Overlay.of(context).insert(_overlayEntry);
          }
          setState(() {
            _isOpen = !_isOpen;
            if (_isOpen) {
              _focusNode.requestFocus();
            } else {
              _focusNode.unfocus();
            }
          });
        },
        child: Container(
          key: _buttonKey,
          width: widget.width ?? double.infinity,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 0),
          margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                decoration: BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: color.outline.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Text(
                        _getThemeLabel(context, currentTheme),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Icon(
                      _isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.outline,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final selectedTheme = themeBloc.state.name.toLowerCase();

    RenderBox renderBox =
    _buttonKey.currentContext!.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    double buttonWidth = renderBox.size.width;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              _overlayEntry.remove();
              setState(() {
                _isOpen = false;
              });
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + renderBox.size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: buttonWidth,
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: _themeModes.map((theme) {
                    bool isSelected = theme['mode'] == selectedTheme;

                    return GestureDetector(
                      onTap: () {
                        themeBloc.add(
                          ChangeThemeEvent(theme['mode']),
                        );
                        _overlayEntry.remove();
                        setState(() {
                          _isOpen = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: .3)
                              : Theme.of(context).colorScheme.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              theme['icon'],
                              size: 18,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getThemeLabel(context, theme['mode']),
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Toggle Button Style (Fixed warnings)
class ThemeToggleSelector extends StatelessWidget {
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String title;

  const ThemeToggleSelector({
    super.key,
    this.padding,
    this.margin,
    this.width,
    this.title = "",
  });

  String _getThemeLabel(BuildContext context, String mode) {
    switch (mode) {
      case 'system':
        return AppLocalizations.of(context)!.systemMode;
      case 'light':
        return AppLocalizations.of(context)!.lightMode;
      case 'dark':
        return AppLocalizations.of(context)!.darkMode;
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeBloc>();
    final currentTheme = themeCubit.state.name.toLowerCase();
    final color = Theme.of(context).colorScheme;

    final List<ThemeOption> themeOptions = [
      ThemeOption(
        mode: 'system',
        icon: Icons.settings,
        label: _getThemeLabel(context, 'system'),
      ),
      ThemeOption(
        mode: 'light',
        icon: Icons.light_mode,
        label: _getThemeLabel(context, 'light'),
      ),
      ThemeOption(
        mode: 'dark',
        icon: Icons.dark_mode,
        label: _getThemeLabel(context, 'dark'),
      ),
    ];

    return Container(
      width: width ?? double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 0),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                 AppLocalizations.of(context)!.theme,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color.onSurface,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: themeOptions.map((option) {
                final bool isSelected = option.mode == currentTheme;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      themeCubit.add(ChangeThemeEvent(option.mode));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.primaryContainer.withValues(alpha: 0.9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            option.icon,
                            size: 24,
                            color: isSelected
                                ? color.primary
                                : color.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            option.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? color.primary
                                  : color.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Android Segmented Style (Fixed warnings)
class AndroidStyleThemeSelector extends StatelessWidget {
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String title;

  const AndroidStyleThemeSelector({
    super.key,
    this.padding,
    this.margin,
    this.width,
    this.title = "",
  });

  String _getThemeLabel(BuildContext context, String mode) {
    switch (mode) {
      case 'system':
        return AppLocalizations.of(context)!.systemMode;
      case 'light':
        return AppLocalizations.of(context)!.lightMode;
      case 'dark':
        return AppLocalizations.of(context)!.darkMode;
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeBloc>();
    final currentTheme = themeCubit.state.name.toLowerCase();
    final color = Theme.of(context).colorScheme;

    final List<ThemeOption> themeOptions = [
      ThemeOption(
        mode: 'system',
        icon: Icons.settings,
        label: _getThemeLabel(context, 'system'),
      ),
      ThemeOption(
        mode: 'light',
        icon: Icons.light_mode,
        label: _getThemeLabel(context, 'light'),
      ),
      ThemeOption(
        mode: 'dark',
        icon: Icons.dark_mode,
        label: _getThemeLabel(context, 'dark'),
      ),
    ];

    return Container(
      width: width ?? double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 0),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color.onSurface,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: color.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: color.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: themeOptions.map((option) {
                final bool isSelected = option.mode == currentTheme;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          themeCubit.add(ChangeThemeEvent(option.mode));
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option.icon,
                                size: 20,
                                color: isSelected
                                    ? color.primary
                                    : color.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? color.primary
                                      : color.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeOption {
  final String mode;
  final IconData icon;
  final String label;

  const ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
  });
}