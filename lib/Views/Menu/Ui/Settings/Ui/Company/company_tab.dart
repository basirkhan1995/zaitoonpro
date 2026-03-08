import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Views/Auth/Subscription/Ui/subscription.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Company/Storage/storage.dart';
import '../../../../../../Features/Generic/generic_menu.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';
import 'Branches/Ui/branches.dart';
import 'CompanyProfile/company.dart';
import 'bloc/company_settings_menu_bloc.dart';

class CompanyTabsView extends StatefulWidget {
  const CompanyTabsView({super.key});

  @override
  State<CompanyTabsView> createState() => _CompanyTabsViewState();
}

class _CompanyTabsViewState extends State<CompanyTabsView> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    // Detect if mobile using MediaQuery
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final menuItems = [
      if (login.hasPermission(69) ?? false)
        MenuDefinition(
          value: CompanySettingsMenuName.profile,
          label: AppLocalizations.of(context)!.profile,
          screen: const CompanySettingsView(),
          icon: Icons.settings,
        ),
      if (login.hasPermission(70) ?? false)
        MenuDefinition(
          value: CompanySettingsMenuName.branch,
          label: AppLocalizations.of(context)!.branch,
          screen: const BranchesView(),
          icon: Icons.location_city_rounded,
        ),
      if (login.hasPermission(71) ?? false)
        MenuDefinition(
          value: CompanySettingsMenuName.storage,
          label: AppLocalizations.of(context)!.storages,
          screen: const StorageView(),
          icon: Icons.inventory_2_rounded,
        ),
      if (login.hasPermission(64) ?? false)
        MenuDefinition(
          value: CompanySettingsMenuName.subscriptions,
          label: "Subscription",
          screen: const SubscriptionView(),
          icon: Icons.subscriptions,
        ),
    ];

    return BlocBuilder<CompanySettingsMenuBloc, CompanySettingsMenuState>(
      builder: (context, blocState) {
        if (isMobile) {
          // Mobile layout with bottom navigation bar
          final currentIndex = menuItems.indexWhere(
                (item) => item.value == blocState.tabs,
          );

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: IndexedStack(
              index: currentIndex >= 0 ? currentIndex : 0,
              children: menuItems.map((item) => item.screen).toList(),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(
              context,
              menuItems,
              blocState.tabs,
            ),
          );
        } else {
          // Desktop/Tablet layout with side menu
          return GenericMenuWithScreen(
            isExpanded: false,
            menuWidth: 160,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            selectedColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: .09),
            selectedTextColor: Theme.of(context).colorScheme.primary,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
            selectedValue: blocState.tabs,
            onChanged: (value) => context
                .read<CompanySettingsMenuBloc>()
                .add(CompanySettingsOnChangedEvent(value)),
            items: menuItems,
          );
        }
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, List<MenuDefinition> menuItems, CompanySettingsMenuName currentTab) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: menuItems.map((item) {
              final isSelected = item.value == currentTab;
              return Expanded(
                child: InkWell(
                  onTap: () => context
                      .read<CompanySettingsMenuBloc>()
                      .add(CompanySettingsOnChangedEvent(item.value)),
                  borderRadius: BorderRadius.circular(8),
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
    );
  }
}