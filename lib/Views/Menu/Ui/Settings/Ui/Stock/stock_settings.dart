import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Stock/Ui/ProductCategory/pro_cat_view.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/products.dart';
import '../../../../../../Features/Generic/generic_menu.dart';
import '../../../../../../Features/Other/responsive.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';
import 'bloc/stock_settings_tab_bloc.dart';

class StockSettingsView extends StatelessWidget {
  const StockSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileStockSettings(),
      tablet: _TabletStockSettings(),
      desktop: _DesktopStockSettings(),
    );
  }
}

// Base class to share common functionality
class _BaseStockSettings extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseStockSettings({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    final locale = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final menuItems = [
      if (login.hasPermission(74) ?? false)
        MenuDefinition(
          value: StockSettingsTabName.products,
          label: locale.products,
          screen: const ProductsView(),
          icon: Icons.production_quantity_limits_rounded,
        ),
      if (login.hasPermission(75) ?? false)
        MenuDefinition(
          value: StockSettingsTabName.proCategory,
          label: locale.categoryTitle,
          screen: const ProCatView(),
          icon: Icons.dialpad_rounded,
        ),
    ];

    if (isMobile) {
      // Mobile layout with bottom navigation bar
      return BlocBuilder<StockSettingsTabBloc, StockSettingsTabState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: IndexedStack(
              index: menuItems.indexWhere((item) => item.value == state.tab),
              children: menuItems.map((item) => item.screen).toList(),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: menuItems.map((item) {
                      final isSelected = item.value == state.tab;
                      return Expanded(
                        child: InkWell(
                          onTap: () => context.read<StockSettingsTabBloc>().add(
                            StockSettingsTabOnChangedEvent(item.value),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          );
        },
      );
    } else if (isTablet) {
      // Tablet layout with side-by-side menu and content
      return BlocBuilder<StockSettingsTabBloc, StockSettingsTabState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: Text(locale.stock),
              centerTitle: true,
              elevation: 0,
              backgroundColor: colorScheme.surface,
            ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Side menu for tablet
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: colorScheme.outline.withValues(alpha: .1),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      ...menuItems.map((item) {
                        final isSelected = item.value == state.tab;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: .1)
                                : Colors.transparent,
                          ),
                          child: ListTile(
                            onTap: () => context.read<StockSettingsTabBloc>().add(
                              StockSettingsTabOnChangedEvent(item.value),
                            ),
                            leading: Icon(
                              item.icon,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              size: 20,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            dense: true,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Content area
                Expanded(
                  child: IndexedStack(
                    index: menuItems.indexWhere((item) => item.value == state.tab),
                    children: menuItems.map((item) => item.screen).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Desktop layout (original)
      return BlocBuilder<StockSettingsTabBloc, StockSettingsTabState>(
        builder: (context, state) {
          return GenericMenuWithScreen(
            isExpanded: false,
            menuWidth: 190,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            selectedColor: colorScheme.primary.withValues(alpha: .09),
            selectedTextColor: colorScheme.onSurface,
            unselectedTextColor: colorScheme.secondary,
            selectedValue: state.tab,
            onChanged: (value) => context.read<StockSettingsTabBloc>().add(
              StockSettingsTabOnChangedEvent(value),
            ),
            items: menuItems,
          );
        },
      );
    }
  }
}

// Mobile View
class _MobileStockSettings extends StatelessWidget {
  const _MobileStockSettings();

  @override
  Widget build(BuildContext context) {
    return const _BaseStockSettings(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletStockSettings extends StatelessWidget {
  const _TabletStockSettings();

  @override
  Widget build(BuildContext context) {
    return const _BaseStockSettings(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopStockSettings extends StatelessWidget {
  const _DesktopStockSettings();

  @override
  Widget build(BuildContext context) {
    return const _BaseStockSettings(
      isMobile: false,
      isTablet: false,
    );
  }
}