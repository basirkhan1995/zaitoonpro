import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/Ui/Accounts/stk_accounts.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/Ui/Users/stk_users.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/bloc/ind_detail_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../Features/Generic/tab_bar.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';

class IndividualsDetailsTabView extends StatelessWidget {
  final IndividualsModel ind;
  const IndividualsDetailsTabView({super.key, required this.ind});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(ind), tablet: _Desktop(ind), desktop: _Desktop(ind));
  }
}

class _Mobile extends StatelessWidget {
  final IndividualsModel ind;
  const _Mobile(this.ind);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("${ind.perName} ${ind.perLastName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: BlocBuilder<IndividualDetailTabBloc, IndividualDetailTabState>(
          builder: (context, state) {
            final tabs = <ZTabItem<IndividualDetailTabName>>[
              if (login.hasPermission(33) ?? false)
                ZTabItem(
                  value: IndividualDetailTabName.accounts,
                  label: AppLocalizations.of(context)!.accounts,
                  screen: AccountsByPerIdView(ind: ind),
                ),
              if (login.hasPermission(34) ?? false)
                ZTabItem(
                  value: IndividualDetailTabName.users,
                  label: AppLocalizations.of(context)!.users,
                  screen: UsersByPerIdView(perId: ind.perId!),
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

            // 🟢 FIX: Safely get selected tab with fallback
            final available = tabs.map((t) => t.value).toList();
            final selected = available.contains(state.tab)
                ? state.tab
                : tabs.first.value; // Use tabs.first.value instead of available.first

            return ZTabContainer<IndividualDetailTabName>(
              /// Tab data
              tabs: tabs,
              selectedValue: selected,

              /// Bloc update
              onChanged: (val) => context
                  .read<IndividualDetailTabBloc>()
                  .add(IndOnChangedEvent(val)),

              /// Colors for underline style
              style: ZTabStyle.rounded,
              tabBarPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
class _Desktop extends StatelessWidget {
  final IndividualsModel ind;
  const _Desktop(this.ind);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    return Scaffold(
      body: BlocBuilder<IndividualDetailTabBloc, IndividualDetailTabState>(
        builder: (context, state) {
          final tabs = <ZTabItem<IndividualDetailTabName>>[
            if (login.hasPermission(33) ?? false)
              ZTabItem(
                value: IndividualDetailTabName.accounts,
                label: AppLocalizations.of(context)!.accounts,
                screen: AccountsByPerIdView(ind: ind),
              ),
            if (login.hasPermission(34) ?? false)
              ZTabItem(
                value: IndividualDetailTabName.users,
                label: AppLocalizations.of(context)!.users,
                screen: UsersByPerIdView(perId: ind.perId!),
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

          // 🟢 FIX: Safely get selected tab with fallback
          final available = tabs.map((t) => t.value).toList();
          final selected = available.contains(state.tab)
              ? state.tab
              : tabs.first.value; // Use tabs.first.value instead of available.first

          return ZTabContainer<IndividualDetailTabName>(
            /// Tab data
            tabs: tabs,
            selectedValue: selected,

            /// Bloc update
            onChanged: (val) => context.read<IndividualDetailTabBloc>().add(IndOnChangedEvent(val)),

            /// Colors for underline style
            style: ZTabStyle.underline,
            tabBarPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),

            borderRadius: 0,
            title: AppLocalizations.of(context)!.accountsAndUsers,
            selectedColor: Theme.of(context).colorScheme.primary,
            description: AppLocalizations.of(context)!.stakeholderManage,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            tabContainerColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }
}

