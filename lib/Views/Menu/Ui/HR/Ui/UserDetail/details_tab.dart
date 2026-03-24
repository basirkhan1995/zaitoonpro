import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Log/user_log.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Overview/user_overview.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Permissions/permissions.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/bloc/user_details_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/model/user_model.dart';
import '../../../../../../Features/Generic/rounded_tab.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';


class UserDetailsTabView extends StatelessWidget {
  final UsersModel user;
  const UserDetailsTabView({super.key,required this.user});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(user), tablet: _Desktop(user), desktop: _Desktop(user));
  }
}

class _Mobile extends StatelessWidget {
  final UsersModel user;
  const _Mobile(this.user);

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: BlocBuilder<UserDetailsTabBloc, UserDetailsTabState>(
        builder: (context, state) {
          final tabs = <TabDefinition<UserDetailsTabNames>>[
            if (login.hasPermission(39) ?? false)
              TabDefinition(
                value: UserDetailsTabNames.overview,
                label: locale.overview,
                screen:  UserOverviewView(user: user),
              ),
            if (login.hasPermission(40) ?? false)
              TabDefinition(
                value: UserDetailsTabNames.permissions,
                label: locale.permissions,
                screen: PermissionsView(user: user),
              ),
            if (login.hasPermission(41) ?? false)
              TabDefinition(
                value: UserDetailsTabNames.usrLog,
                label: locale.userLog,
                screen: UserLogView(usrName: user.usrName),
              ),
          ];

          final availableValues = tabs.map((tab) => tab.value).toList();
          final selected = availableValues.contains(state.tab)
              ? state.tab
              : availableValues.first;

          return GenericTab<UserDetailsTabNames>(
            borderRadius: 0,
            tabContainerColor: Theme.of(context).colorScheme.surface,
            selectedValue: selected,
            onChanged: (val) => context.read<UserDetailsTabBloc>().add(UserDetailsTabOnChangedEvent(val)),
            tabs: tabs,
            selectedColor: Theme.of(context).colorScheme.primary,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
          );

        },
      ),
    );
  }
}


class _Desktop extends StatelessWidget {
  final UsersModel user;
  const _Desktop(this.user);

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: BlocBuilder<UserDetailsTabBloc, UserDetailsTabState>(
        builder: (context, state) {
          final tabs = <TabDefinition<UserDetailsTabNames>>[
            if (login.hasPermission(39) ?? false)
              TabDefinition(
                value: UserDetailsTabNames.overview,
                label: locale.overview,
                screen:  UserOverviewView(user: user),
              ),
            if (login.hasPermission(40) ?? false)
              TabDefinition(
                value: UserDetailsTabNames.permissions,
                label: locale.permissions,
                screen: PermissionsView(user: user),
              ),
            if (login.hasPermission(41) ?? false)
              TabDefinition(
                value: UserDetailsTabNames.usrLog,
                label: locale.userLog,
                screen: UserLogView(usrName: user.usrName),
              ),
          ];

          final availableValues = tabs.map((tab) => tab.value).toList();
          final selected = availableValues.contains(state.tab)
              ? state.tab
              : availableValues.first;

          return GenericTab<UserDetailsTabNames>(
            borderRadius: 0,
            title: AppLocalizations.of(context)!.userManagement,
            description: AppLocalizations.of(context)!.manageUser,
            tabContainerColor: Theme.of(context).colorScheme.surface,
            selectedValue: selected,
            onChanged: (val) => context.read<UserDetailsTabBloc>().add(UserDetailsTabOnChangedEvent(val)),
            tabs: tabs,
            selectedColor: Theme.of(context).colorScheme.primary,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
          );

        },
      ),
    );
  }
}


