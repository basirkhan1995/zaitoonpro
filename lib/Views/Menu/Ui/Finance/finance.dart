import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/EndOfYear/end_year.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/gl_accounts.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Payroll/payroll.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Reminder/reminder.dart';
import '../../../../Features/Generic/tab_bar.dart';
import '../../../../Localizations/l10n/translations/app_localizations.dart';
import 'Ui/Currency/currency.dart';
import 'bloc/financial_tab_bloc.dart';


class FinanceView extends StatelessWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
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

      body: BlocBuilder<FinanceTabBloc, FinanceTabState>(
        builder: (context, state) {
          final tabs = <ZTabItem<FinanceTabName>>[
            if (login.hasPermission(11) ?? false)...[
              ZTabItem(
                value: FinanceTabName.currencies,
                label: AppLocalizations.of(context)!.currencyTitle,
                screen: const CurrencyTabView(),
              ),
            ],

            if (login.hasPermission(14) ?? false)...[
              ZTabItem(
                value: FinanceTabName.glAccounts,
                label: AppLocalizations.of(context)!.glAccounts,
                screen: const GlAccountsView(),
              ),
            ],

            if (login.hasPermission(15) ?? false)...[
              ZTabItem(
                value: FinanceTabName.payroll,
                label: AppLocalizations.of(context)!.payRoll,
                screen: const PayrollView(),
              ),
            ],

            if (login.hasPermission(16) ?? false) ...[
              ZTabItem(
                value: FinanceTabName.endOfYear,
                label: AppLocalizations.of(context)!.fiscalYear,
                screen: const EndOfYearView(),
              ),
            ],
            if (login.hasPermission(17) ?? false) ...[
              ZTabItem(
                value: FinanceTabName.reminder,
                label: AppLocalizations.of(context)!.reminders,
                screen: const ReminderView(),
              ),
            ]];

          if (tabs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 50,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  Text(
                    AppLocalizations.of(context)!.deniedPermissionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    AppLocalizations.of(context)!.deniedPermissionMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final availableValues = tabs.map((tab) => tab.value).toList();
          final selected = availableValues.contains(state.tab)
              ? state.tab
              : availableValues.first;

          return ZTabContainer<FinanceTabName>(
            /// Tab data
            tabs: tabs,
            selectedValue: selected,
            title: AppLocalizations.of(context)!.finance,
            description: AppLocalizations.of(context)!.manageFinance,

            /// Bloc update
            onChanged: (val) => context.read<FinanceTabBloc>().add(
              FinanceOnChangedEvent(val),
            ),

            /// Colors and style
            style: ZTabStyle.rounded,
            tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
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

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BlocBuilder<FinanceTabBloc, FinanceTabState>(
          builder: (context, state) {
            final tabs = <ZTabItem<FinanceTabName>>[
              if (login.hasPermission(11) ?? false)...[
                ZTabItem(
                  value: FinanceTabName.currencies,
                  label: AppLocalizations.of(context)!.currencyTitle,
                  screen: const CurrencyTabView(),
                ),
              ],

              if (login.hasPermission(14) ?? false)...[
                ZTabItem(
                  value: FinanceTabName.glAccounts,
                  label: AppLocalizations.of(context)!.glAccounts,
                  screen: const GlAccountsView(),
                ),
              ],

              if (login.hasPermission(17) ?? false) ...[
                ZTabItem(
                  value: FinanceTabName.reminder,
                  label: AppLocalizations.of(context)!.reminders,
                  screen: const ReminderView(),
                ),
              ]];

            if (tabs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    Text(
                      AppLocalizations.of(context)!.deniedPermissionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      AppLocalizations.of(context)!.deniedPermissionMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            final availableValues = tabs.map((tab) => tab.value).toList();
            final selected = availableValues.contains(state.tab)
                ? state.tab
                : availableValues.first;

            return ZTabContainer<FinanceTabName>(
              /// Tab data
              tabs: tabs,
              selectedValue: selected,

              /// Bloc update
              onChanged: (val) => context.read<FinanceTabBloc>().add(
                FinanceOnChangedEvent(val),
              ),

              /// Colors and style
              style: ZTabStyle.rounded,
              tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
              borderRadius: 0,
              selectedColor: Theme.of(context).colorScheme.primary,
              unselectedTextColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.surface,
              tabContainerColor: Theme.of(context).colorScheme.surface,
            );
          },
        ),
      ),
    );
  }
}