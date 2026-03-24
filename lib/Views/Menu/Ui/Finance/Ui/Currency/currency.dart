import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/Ui/exchange_rate.dart';
import '../../../../../../Features/Generic/generic_menu.dart';
import '../../../../../../Features/Other/responsive.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import 'Ui/Currencies/Ui/currencies.dart';
import 'bloc/currency_tab_bloc.dart';

class CurrencyTabView extends StatelessWidget {
  const CurrencyTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileCurrencyView(),
      tablet: _TabletCurrencyView(),
      desktop: _DesktopCurrencyView(),
    );
  }
}

// Base class to share common functionality
class _BaseCurrencyView extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseCurrencyView({
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
      if (login.hasPermission(12) ?? false)
        MenuDefinition(
          value: CurrencyTabName.currency,
          label: locale.currencyTitle,
          screen: const CurrenciesView(),
          icon: Icons.currency_yen_rounded,
        ),
      if (login.hasPermission(13) ?? false)
        MenuDefinition(
          value: CurrencyTabName.rates,
          label: locale.exchangeRate,
          screen: const ExchangeRateView(
            newRateButton: true,
            settingButton: false,
          ),
          icon: Icons.ssid_chart_outlined,
        ),
    ];

    if (isMobile) {
      // Mobile layout with bottom navigation bar
      return BlocBuilder<CurrencyTabBloc, CurrencyTabState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: IndexedStack(
              index: menuItems.indexWhere((item) => item.value == state.tabs),
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
                      final isSelected = item.value == state.tabs;
                      return Expanded(
                        child: InkWell(
                          onTap: () => context.read<CurrencyTabBloc>().add(
                            CcyOnChangedEvent(item.value),
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
      return BlocBuilder<CurrencyTabBloc, CurrencyTabState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: Text(locale.currencyTitle),
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
                        final isSelected = item.value == state.tabs;
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
                            onTap: () => context.read<CurrencyTabBloc>().add(
                              CcyOnChangedEvent(item.value),
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
                    index: menuItems.indexWhere((item) => item.value == state.tabs),
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
      return BlocBuilder<CurrencyTabBloc, CurrencyTabState>(
        builder: (context, state) {
          return GenericMenuWithScreen(
            menuWidth: 190,
            isExpanded: false,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            selectedColor: colorScheme.primary.withValues(alpha: .09),
            selectedTextColor: colorScheme.primary,
            unselectedTextColor: colorScheme.secondary,
            selectedValue: state.tabs,
            onChanged: (value) =>
                context.read<CurrencyTabBloc>().add(CcyOnChangedEvent(value)),
            items: menuItems,
          );
        },
      );
    }
  }
}

// Mobile View
class _MobileCurrencyView extends StatelessWidget {
  const _MobileCurrencyView();

  @override
  Widget build(BuildContext context) {
    return const _BaseCurrencyView(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletCurrencyView extends StatelessWidget {
  const _TabletCurrencyView();

  @override
  Widget build(BuildContext context) {
    return const _BaseCurrencyView(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopCurrencyView extends StatelessWidget {
  const _DesktopCurrencyView();

  @override
  Widget build(BuildContext context) {
    return const _BaseCurrencyView(
      isMobile: false,
      isTablet: false,
    );
  }
}