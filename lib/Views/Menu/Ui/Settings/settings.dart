import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Views/Auth/models/login_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Backup/backup.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Company/company_tab.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Services/Ui/services.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Stock/stock_settings.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/TxnTypes/txn_types_view.dart';
import '../../../../Features/Generic/tab_bar.dart';
import '../../../../Features/Other/responsive.dart';
import '../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import 'Ui/About/about.dart';
import 'Ui/General/general.dart';
import 'bloc/settings_tab_bloc.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(),
      tablet: _Desktop(),
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: BlocBuilder<SettingsTabBloc, SettingsTabState>(
        builder: (context, state) {
          final tabs = <ZTabItem<SettingsTabName>>[

            if (login.hasPermission(63) ?? false)
              ZTabItem(
                value: SettingsTabName.general,
                label: AppLocalizations.of(context)!.general,
                screen: const GeneralView(),
              ),

            if (login.hasPermission(68) ?? false)
              ZTabItem(
                value: SettingsTabName.company,
                label: AppLocalizations.of(context)!.company,
                screen: const CompanyTabsView(),
              ),

            if (login.hasPermission(49) ?? false)
              ZTabItem(
                value: SettingsTabName.services,
                label: AppLocalizations.of(context)!.services,
                screen: const ServicesView(),
              ),

            if ((login.usrRole == "Super") || (login.hasPermission(72) ?? false))
              ZTabItem(
                value: SettingsTabName.txnTypes,
                label: AppLocalizations.of(context)!.transactionType,
                screen: const TxnTypesView(),
              ),

            if (login.hasPermission(73) ?? false)
            ZTabItem(
              value: SettingsTabName.stock,
              label: AppLocalizations.of(context)!.stock,
              screen: const StockSettingsView(),
            ),

            if (login.hasPermission(76) ?? false)
              ZTabItem(
                value: SettingsTabName.backup,
                label: AppLocalizations.of(context)!.backupTitle,
                screen: const BackupView(),
              ),

            if (login.hasPermission(77) ?? false)
            ZTabItem(
              value: SettingsTabName.about,
              label: AppLocalizations.of(context)!.about,
              screen: const AboutView(),
            ),

          ];

          // 🟢 FIX: Handle empty tabs case
          if (tabs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.no_accounts_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.accessDenied,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please contact administrator",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
                    ),
                  ),
                ],
              ),
            );
          }

          final availableValues = tabs.map((tab) => tab.value).toList();
          final selected = availableValues.contains(state.tabs)
              ? state.tabs
              : availableValues.first;

          return ZTabContainer<SettingsTabName>(
            /// Tab data
            tabs: tabs,
            selectedValue: selected,
            /// Bloc update
            onChanged: (val) => context.read<SettingsTabBloc>().add(SettingsOnChangeEvent(val)),
            title: AppLocalizations.of(context)!.settings,
            description: AppLocalizations.of(context)!.settingsHint,
            /// Colors and style
            style: ZTabStyle.rounded,
            tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
            borderRadius: 0,
            selectedColor: Theme.of(context).colorScheme.primary,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            tabContainerColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: BlocBuilder<SettingsTabBloc, SettingsTabState>(
        builder: (context, state) {
          final tabs = <ZTabItem<SettingsTabName>>[
            if (login.hasPermission(63) ?? false)
              ZTabItem(
                value: SettingsTabName.general,
                label: AppLocalizations.of(context)!.general,
                screen: const GeneralView(),
              ),

            if (login.hasPermission(68) ?? false)
              ZTabItem(
                value: SettingsTabName.company,
                label: AppLocalizations.of(context)!.company,
                screen: const CompanyTabsView(),
              ),
            if (login.hasPermission(49) ?? false)
              ZTabItem(
                value: SettingsTabName.services,
                label: AppLocalizations.of(context)!.services,
                screen: const ServicesView(),
              ),
            if (login.hasPermission(73) ?? false)
              ZTabItem(
                value: SettingsTabName.stock,
                label: AppLocalizations.of(context)!.stock,
                screen: const StockSettingsView(),
              ),

            if ((login.usrRole == "Super") || (login.hasPermission(72) ?? false))
              ZTabItem(
                value: SettingsTabName.txnTypes,
                label: AppLocalizations.of(context)!.transactionType,
                screen: const TxnTypesView(),
              ),

            if (login.hasPermission(76) ?? false)
              ZTabItem(
                value: SettingsTabName.backup,
                label: AppLocalizations.of(context)!.backupTitle,
                screen: const BackupView(),
              ),

            if (login.hasPermission(77) ?? false)
              ZTabItem(
                value: SettingsTabName.about,
                label: AppLocalizations.of(context)!.about,
                screen: const AboutView(),
              ),

          ];
          // 🟢 FIX: Handle empty tabs case
          if (tabs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.no_accounts_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.accessDenied,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please contact administrator",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
                    ),
                  ),
                ],
              ),
            );
          }
          final availableValues = tabs.map((tab) => tab.value).toList();
          final selected = availableValues.contains(state.tabs)
              ? state.tabs
              : availableValues.first;

          return ZTabContainer<SettingsTabName>(
            /// Tab data
            tabs: tabs,
            selectedValue: selected,
            /// Bloc update
            onChanged: (val) => context.read<SettingsTabBloc>().add(SettingsOnChangeEvent(val)),

            /// Colors and style
            style: ZTabStyle.rounded,
            tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
            borderRadius: 0,
            selectedColor: Theme.of(context).colorScheme.primary,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            tabContainerColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }
}

