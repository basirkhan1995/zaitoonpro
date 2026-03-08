import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/General/Ui/UserProfileSettings/user_profile_settings.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/General/Ui/UserRole/user_role_settings.dart';
import '../../../../../../Features/Generic/generic_menu.dart';
import '../../../../../../Features/Other/responsive.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';
import 'Ui/DefaultPermissions/permission_settings.dart';
import 'Ui/Security/password.dart';
import 'Ui/System/system.dart';
import 'bloc/general_tab_bloc.dart';

class GeneralView extends StatelessWidget {
  const GeneralView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileGeneralView(),
      tablet: _DesktopGeneralView(),
      desktop: _DesktopGeneralView(),
    );
  }
}

// Base class to share common functionality
class _BaseGeneralView extends StatelessWidget {
  final bool isMobile;

  const _BaseGeneralView({
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    final colorScheme = Theme.of(context).colorScheme;

    final menuItems = [

      if (login.hasPermission(64) ?? false)
        MenuDefinition(
          value: GeneralTabName.system,
          label: AppLocalizations.of(context)!.systemSettings,
          screen: const SystemView(),
          icon: Icons.settings,
        ),

      if (login.hasPermission(65) ?? false)
        MenuDefinition(
          value: GeneralTabName.password,
          label: AppLocalizations.of(context)!.password,
          screen: const PasswordView(),
          icon: Icons.lock,
        ),
      if (login.hasPermission(67) ?? false)
        MenuDefinition(
          value: GeneralTabName.roles,
          label: AppLocalizations.of(context)!.userRole,
          screen: const UserRoleSettingsView(),
          icon: Icons.verified_user_outlined,
        ),
      if (login.hasPermission(67) ?? false)
        MenuDefinition(
          value: GeneralTabName.permissions,
          label: AppLocalizations.of(context)!.rolesAndPermissions,
          screen: const PermissionSettingsView(),
          icon: Icons.verified_user,
        ),
      if (login.hasPermission(66) ?? false)
        MenuDefinition(
          value: GeneralTabName.profileSettings,
          label: AppLocalizations.of(context)!.profileSettings,
          screen: const UserProfileSettingsView(),
          icon: Icons.account_circle,
        ),
    ];

    // Handle empty tabs case
    if (menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts_rounded,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.accessDenied,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please contact administrator",
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: .4),
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<GeneralTabBloc, GeneralTabState>(
      builder: (context, blocState) {
        if (isMobile) {
          // Mobile layout with bottom navigation bar
          final currentIndex = menuItems.indexWhere(
                (item) => item.value == blocState.tab,
          );

          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: IndexedStack(
              index: currentIndex >= 0 ? currentIndex : 0,
              children: menuItems.map((item) => item.screen).toList(),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(
              context,
              menuItems,
              blocState.tab,
            ),
          );
        } else {
          // Desktop/Tablet layout with side menu
          return GenericMenuWithScreen(
            isExpanded: false,
            menuWidth: 210,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            selectedColor: colorScheme.primary.withValues(alpha: .09),
            selectedTextColor: colorScheme.onSurface,
            unselectedTextColor: colorScheme.secondary,
            selectedValue: blocState.tab,
            onChanged: (value) => context.read<GeneralTabBloc>().add(GeneralTabOnChangedEvent(value)),
            items: menuItems,
          );
        }
      },
    );
  }

  Widget _buildBottomNavigationBar(
      BuildContext context,
      List<MenuDefinition> menuItems,
      GeneralTabName currentTab,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                      .read<GeneralTabBloc>()
                      .add(GeneralTabOnChangedEvent(item.value)),
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

// Mobile View
class _MobileGeneralView extends StatelessWidget {
  const _MobileGeneralView();

  @override
  Widget build(BuildContext context) {
    return const _BaseGeneralView(
      isMobile: true,
    );
  }
}

// Desktop/Tablet View
class _DesktopGeneralView extends StatelessWidget {
  const _DesktopGeneralView();

  @override
  Widget build(BuildContext context) {
    return const _BaseGeneralView(
      isMobile: false,
    );
  }
}