import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoon_petroleum/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoon_petroleum/Views/Auth/Ui/login.dart';
import 'package:zaitoon_petroleum/Views/Auth/models/login_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/hr.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/Ui/AllProjects/all_projects.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Individuals/Ui/individuals.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Transport/transport.dart';
import '../../Features/Generic/generic_menu.dart';
import '../../Features/Other/image_helper.dart';
import '../../Features/Other/responsive.dart';
import '../../Features/Other/utils.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';
import 'Ui/Dashboard/dashboard.dart';
import 'Ui/Finance/finance.dart';
import 'Ui/Journal/journal.dart';
import 'Ui/Report/report.dart';
import 'Ui/Settings/Ui/Company/bloc/company_settings_menu_bloc.dart';
import 'Ui/Settings/bloc/settings_tab_bloc.dart';
import 'Ui/Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import 'Ui/Settings/settings.dart';
import 'Ui/Stock/stock.dart';
import 'bloc/menu_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MenuBloc()),
      ],
      child: const ResponsiveLayout(
        mobile: _Mobile(),
        tablet: _Tablet(),
        desktop: _Desktop(),
      ),
    );
  }
}

// ================== DESKTOP ==================

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> with AutomaticKeepAliveClientMixin {
  Uint8List? _cachedLogo;
  String? _cachedComName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProfileBloc>().add(LoadCompanyProfileEvent());
    });
  }

  void _logout() async {
    final authBloc = context.read<AuthBloc>();
    authBloc.add(OnLogoutEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Use context.select here, at the top of build method
    final currentTab = context.select((MenuBloc bloc) => bloc.state.tabs);
    final authState = context.select((AuthBloc bloc) => bloc.state);
    final visibility = context.watch<SettingsVisibleBloc>().state;
    if (authState is! AuthenticatedState) return const SizedBox();

    final String adminName = authState.loginData.usrFullName ?? "";
    final String usrPhoto = authState.loginData.usrPhoto ??"";
    final String usrRole = authState.loginData.usrRole ?? "";

    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    final menuItems = [
      if(login.hasPermission(1) ?? false)...[
        MenuDefinition(
          value: MenuName.dashboard,
          label: AppLocalizations.of(context)!.dashboard,
          screen: const DashboardView(),
          icon: Icons.add_home_outlined,
        ),
      ],

    if(login.hasPermission(10) ?? false)...[
      MenuDefinition(
        value: MenuName.finance,
        label: AppLocalizations.of(context)!.finance,
        screen: const FinanceView(),
        icon: Icons.money,
      ),
    ],

    if(login.hasPermission(18) ?? false)...[
      MenuDefinition(
        value: MenuName.journal,
        label: AppLocalizations.of(context)!.journal,
        screen: const JournalView(),
        icon: Icons.menu_book,
      ),
    ],

    if(login.hasPermission(31) ?? false)...[
      MenuDefinition(
        value: MenuName.stakeholders,
        label: AppLocalizations.of(context)!.stakeholders,
        screen: const IndividualsView(),
        icon: Icons.account_circle_outlined,
      ),
    ],

    if(login.hasPermission(35) ?? false)...[
      MenuDefinition(
        value: MenuName.hr,
        label: AppLocalizations.of(context)!.hr,
        screen: const HrTabView(),
        icon: Icons.group_rounded,
      ),
    ],

    if(login.hasPermission(42) ?? false)...[
      if(visibility.transport)...[
        MenuDefinition(
          value: MenuName.transport,
          label: AppLocalizations.of(context)!.transport,
          screen: const TransportView(),
          icon: Icons.fire_truck_rounded,
        ),
      ],
    ],
      if(login.hasPermission(46) ?? false)...[
          MenuDefinition(
            value: MenuName.projects,
            label: AppLocalizations.of(context)!.projects,
            screen: const AllProjectsView(),
            icon: Icons.folder_open_rounded,
          ),
      ],

    if(login.hasPermission(51) ?? false)...[
    if(visibility.orders)...[
      MenuDefinition(
        value: MenuName.stock,
        label: AppLocalizations.of(context)!.inventory,
        screen: const StockView(),
        icon: Icons.shopping_basket_outlined,
      ),
    ],
    ],

    if(login.hasPermission(62) ?? false)...[
      MenuDefinition(
        value: MenuName.settings,
        label: AppLocalizations.of(context)!.settings,
        screen: const SettingsView(),
        icon: Icons.settings_outlined,
      ),
    ],
    if(login.hasPermission(78) ?? false)...[
      MenuDefinition(
        value: MenuName.report,
        label: AppLocalizations.of(context)!.reports,
        screen: const ReportView(),
        icon: Icons.info_outlined,
      ),
    ]];
    if (menuItems.isEmpty) {
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
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is UnAuthenticatedState) {
            Utils.gotoReplacement(context, const LoginView());
          }
        },
        child: GenericMenuWithScreen<MenuName>(
          key: const Key('main_menu'),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          selectedValue: currentTab,
          onChanged: (val) {
            // Only update if the tab is different
            if (currentTab != val) {
              context.read<MenuBloc>().add(MenuOnChangedEvent(val));
            }
          },
          items: menuItems,
          selectedColor: Theme.of(context).colorScheme.primary.withAlpha(23),
          selectedTextColor: Theme.of(context).colorScheme.primary.withAlpha(230),
          unselectedTextColor: Theme.of(context).colorScheme.secondary,
          menuHeaderBuilder: (isExpanded) {
            return BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
              listener: (context, state) {
                // Cache the logo and company name when loaded
                if (state is CompanyProfileLoadedState) {
                  if (_cachedComName != state.company.comName) {
                    _cachedComName = state.company.comName;
                  }

                  final base64Logo = state.company.comLogo;
                  if (base64Logo != null && base64Logo.isNotEmpty) {
                    try {
                      final newLogo = base64Decode(base64Logo);
                      // Only update if different
                      if (!_areBytesEqual(_cachedLogo, newLogo)) {
                        _cachedLogo = newLogo;
                      }
                    } catch (_) {
                      _cachedLogo = null;
                    }
                  } else {
                    _cachedLogo = null;
                  }
                }
              },
              builder: (context, state) {
                // Use cached values to prevent unnecessary rebuilds
                final logo = _cachedLogo;
                final comName = login.company?.comName ?? "";

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      margin: const EdgeInsets.all(5),
                      width: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(23),
                        ),
                      ),
                      child: logo == null || logo.isEmpty
                          ? Image.asset(
                        "assets/images/zaitoonLogo.png",
                        cacheHeight: 120,
                        cacheWidth: 120,
                      ) : Image.memory(
                        logo,
                        cacheHeight: 110,
                        cacheWidth: 110,
                      ),
                    ),

                    if (isExpanded)
                      InkWell(
                        onTap: () {
                          context.read<MenuBloc>().add(
                            MenuOnChangedEvent(MenuName.settings),
                          );
                          context.read<SettingsTabBloc>().add(
                            SettingsOnChangeEvent(SettingsTabName.company),
                          );
                          context.read<CompanySettingsMenuBloc>().add(
                            CompanySettingsOnChangedEvent(
                              CompanySettingsMenuName.profile,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 150,
                          child: Text(
                            comName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
          menuFooterBuilder: (isExpanded) {
            // Pass the pre-fetched values instead of using context.select here
            return _MenuFooter(
              isExpanded: isExpanded,
              adminName: adminName,
              usrPhoto: usrPhoto,
              usrRole: usrRole,
              onProfileTap: () => _showProfileDialog(context),
            );
          },
        ),
      ),
    );
  }

  bool _areBytesEqual(Uint8List? a, Uint8List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _showProfileDialog(BuildContext context) {
    final authState = context.read<AuthBloc>().state as AuthenticatedState;
    final isEnglish = context.read<LocalizationBloc>().state.languageCode == "en";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          alignment: isEnglish
              ? Alignment.bottomLeft
              : Alignment.bottomRight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _ProfileDialogContent(
              authState: authState,
              onLogout: _logout,
            ),
          ),
        );
      },
    );
  }
}

class _MenuFooter extends StatelessWidget {
  final bool isExpanded;
  final String adminName;
  final String usrPhoto;
  final String usrRole;
  final VoidCallback onProfileTap;

  const _MenuFooter({
    required this.isExpanded,
    required this.adminName,
    required this.usrPhoto,
    required this.usrRole,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
      child: Column(
        mainAxisAlignment: isExpanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        crossAxisAlignment: isExpanded
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onProfileTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ImageHelper.stakeholderProfile(
                  imageName: usrPhoto,
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(77),
                  ),
                  size: 40,
                ),

                if (!isExpanded) const SizedBox.shrink(),

                if (isExpanded) const SizedBox(width: 5),

                if (isExpanded)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          usrRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDialogContent extends StatelessWidget {
  final AuthenticatedState authState;
  final VoidCallback onLogout;

  const _ProfileDialogContent({
    required this.authState,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              child: ImageHelper.stakeholderProfile(
                imageName: authState.loginData.usrPhoto,
                size: 80,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              authState.loginData.usrFullName ?? "No Name",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              authState.loginData.usrName ?? "No Name",
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        const Divider(indent: 10, endIndent: 10),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                icon: Icons.email_outlined,
                text: authState.loginData.usrEmail ?? "No Email",
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.work_outline,
                text: authState.loginData.usrRole ?? "No Role",
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.business_outlined,
                text: authState.loginData.brcName ?? "No Branch",
              ),
            ],
          ),
        ),

        InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onLogout();
          },
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8.0),
            bottomRight: Radius.circular(8.0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
              color: Theme.of(context).colorScheme.error.withAlpha(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.logout,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ================== MOBILE & TABLET DRAWER VERSION ==================

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const _DrawerHomeView(isTablet: false);
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return const _DrawerHomeView(isTablet: true);
  }
}

class _DrawerHomeView extends StatefulWidget {
  final bool isTablet;

  const _DrawerHomeView({required this.isTablet});

  @override
  State<_DrawerHomeView> createState() => _DrawerHomeViewState();
}

class _DrawerHomeViewState extends State<_DrawerHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late MenuName _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = context.read<MenuBloc>().state.tabs;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProfileBloc>().add(LoadCompanyProfileEvent());
    });
  }

  void _logout() async {
    final authBloc = context.read<AuthBloc>();
    authBloc.add(OnLogoutEvent());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return const SizedBox();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnAuthenticatedState) {
          Utils.gotoReplacement(context, const LoginView());
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actionsPadding: EdgeInsets.all(8),
          title: BlocBuilder<MenuBloc, MenuState>(
            builder: (context, state) {
              return Text(
                _getMenuTitle(context, state.tabs),
                style: TextStyle(
                  fontSize: widget.isTablet ? 20 : 18,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          actions: [
            InkWell(
              onTap: () => _showProfileDialog(context),
              child: ImageHelper.stakeholderProfile(
                imageName: authState.loginData.usrPhoto,
                size: 40,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .3),
                ),
              ),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) {
            return _getScreenForMenu(state.tabs);
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return const SizedBox();

    final String adminName = authState.loginData.usrFullName ?? "";
    final String usrPhoto = authState.loginData.usrPhoto ?? "";
    final String usrRole = authState.loginData.usrRole ?? "";
    final login = authState.loginData;
    final visibility = context.watch<SettingsVisibleBloc>().state;

    final drawerWidth = widget.isTablet ? 280.0 : 250.0;

    return Drawer(
      width: drawerWidth,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
        listener: (context, state) {},
        builder: (context, state) {
          final companyName = state is CompanyProfileLoadedState
              ? state.company.comName
              : AppLocalizations.of(context)!.zPetroleum;
          final logo = _getCompanyLogo(state);

          return SafeArea(
            child: Column(
              children: [
                // Drawer Header
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
                          ),
                        ),
                        child: logo != null
                            ? Image.memory(logo, fit: BoxFit.contain)
                            : Image.asset(
                          "assets/images/zaitoonLogo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        companyName ?? "",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Menu Items - WITH PERMISSION CHECKING
                Expanded(
                  child: ListView(
                    children: _buildMenuItems(context, login, visibility),
                  ),
                ),

                // User Profile & Logout
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ImageHelper.stakeholderProfile(
                            imageName: usrPhoto,
                            size: 40,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: .3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  usrRole,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ZOutlineButton(
                          isActive: true,
                          backgroundHover: Theme.of(context).colorScheme.error,
                          onPressed: _logout,
                          label: Text(AppLocalizations.of(context)!.logout),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildMenuItems(
      BuildContext context,
      LoginData login,
      SettingsVisibilityState visibility,
      ) {
    final currentTab = context.watch<MenuBloc>().state.tabs;
    final menuItems = <Widget>[];

    // Dashboard - Permission 1
    if (login.hasPermission(1) ?? false) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.add_home_outlined,
          label: AppLocalizations.of(context)!.dashboard,
          isSelected: currentTab == MenuName.dashboard,
          onTap: () => _onMenuItemTap(MenuName.dashboard),
        ),
      );
    }

    // Finance - Permission 10
    if (login.hasPermission(10) ?? false) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.money,
          label: AppLocalizations.of(context)!.finance,
          isSelected: currentTab == MenuName.finance,
          onTap: () => _onMenuItemTap(MenuName.finance),
        ),
      );
    }

    // Journal - Permission 18
    if (login.hasPermission(18) ?? false) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.menu_book,
          label: AppLocalizations.of(context)!.journal,
          isSelected: currentTab == MenuName.journal,
          onTap: () => _onMenuItemTap(MenuName.journal),
        ),
      );
    }

    // Stakeholders - Permission 31
    if (login.hasPermission(31) ?? false) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.account_circle_outlined,
          label: AppLocalizations.of(context)!.stakeholders,
          isSelected: currentTab == MenuName.stakeholders,
          onTap: () => _onMenuItemTap(MenuName.stakeholders),
        ),
      );
    }

    // HR - Permission 35
    if (login.hasPermission(35) ?? false) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.group_rounded,
          label: AppLocalizations.of(context)!.hr,
          isSelected: currentTab == MenuName.hr,
          onTap: () => _onMenuItemTap(MenuName.hr),
        ),
      );
    }

    // Transport - Permission 42 (with visibility check)
    if ((login.hasPermission(42) ?? false) && visibility.transport) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.fire_truck_rounded,
          label: AppLocalizations.of(context)!.transport,
          isSelected: currentTab == MenuName.transport,
          onTap: () => _onMenuItemTap(MenuName.transport),
        ),
      );
    }

    // Projects - Permission
    if ((login.hasPermission(46) ?? false)) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.folder_open_rounded,
          label: AppLocalizations.of(context)!.projects,
          isSelected: currentTab == MenuName.projects,
          onTap: () => _onMenuItemTap(MenuName.projects),
        ),
      );
    }

    // Stock/Inventory - Permission 66 (with visibility check)
    if ((login.hasPermission(51) ?? false) && visibility.orders) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.shopping_basket_outlined,
          label: AppLocalizations.of(context)!.inventory,
          isSelected: currentTab == MenuName.stock,
          onTap: () => _onMenuItemTap(MenuName.stock),
        ),
      );
    }

    // Settings - Permission 57
    if (login.hasPermission(62) ?? false) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.settings_outlined,
          label: AppLocalizations.of(context)!.settings,
          isSelected: currentTab == MenuName.settings,
          onTap: () => _onMenuItemTap(MenuName.settings),
        ),
      );
    }

    // Report - Permission 71
    if (login.hasPermission(78) ?? false) {
      menuItems.add(
        _DrawerMenuItem(
          icon: Icons.info_outlined,
          label: AppLocalizations.of(context)!.report,
          isSelected: currentTab == MenuName.report,
          onTap: () => _onMenuItemTap(MenuName.report),
        ),
      );
    }

    // If no menu items, show a message
    if (menuItems.isEmpty) {
      menuItems.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Please contact administrator",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return menuItems;
  }

  void _onMenuItemTap(MenuName menuName) {
    if (_currentTab != menuName) {
      setState(() {
        _currentTab = menuName;
      });
      context.read<MenuBloc>().add(MenuOnChangedEvent(menuName));
    }
    // Close drawer on mobile, keep open on tablet
    if (!widget.isTablet) {
      Navigator.pop(context);
    }
  }

  Widget _getScreenForMenu(MenuName menuName) {
    switch (menuName) {
      case MenuName.dashboard:
        return const DashboardView();
      case MenuName.projects:
        return const AllProjectsView();
      case MenuName.finance:
        return const FinanceView();
      case MenuName.journal:
        return const JournalView();
      case MenuName.stakeholders:
        return const IndividualsView();
      case MenuName.hr:
        return const HrTabView();
      case MenuName.transport:
        return const TransportView();
      case MenuName.stock:
        return const StockView();
      case MenuName.settings:
        return const SettingsView();
      case MenuName.report:
        return const ReportView();
    }
  }

  String _getMenuTitle(BuildContext context, MenuName menuName) {
    switch (menuName) {
      case MenuName.dashboard:return AppLocalizations.of(context)!.dashboard;
      case MenuName.finance:return AppLocalizations.of(context)!.finance;
      case MenuName.journal:return AppLocalizations.of(context)!.journal;
      case MenuName.stakeholders:return AppLocalizations.of(context)!.stakeholders;
      case MenuName.hr:return AppLocalizations.of(context)!.hr;
      case MenuName.transport:return AppLocalizations.of(context)!.transport;
      case MenuName.projects:return AppLocalizations.of(context)!.projects;
      case MenuName.stock:return AppLocalizations.of(context)!.stock;
      case MenuName.settings:return AppLocalizations.of(context)!.settings;
      case MenuName.report: return AppLocalizations.of(context)!.report;
    }
  }

  Uint8List? _getCompanyLogo(CompanyProfileState state) {
    if (state is CompanyProfileLoadedState) {
      final base64Logo = state.company.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          return base64Decode(base64Logo);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  void _showProfileDialog(BuildContext context) {
    final authState = context.read<AuthBloc>().state as AuthenticatedState;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: ImageHelper.stakeholderProfile(
                        imageName: authState.loginData.usrPhoto,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authState.loginData.usrFullName ?? "No Name",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      authState.loginData.usrName ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _BottomSheetDetailRow(
                      icon: Icons.email_outlined,
                      text: authState.loginData.usrEmail ?? "No Email",
                    ),
                    const SizedBox(height: 12),
                    _BottomSheetDetailRow(
                      icon: Icons.work_outline,
                      text: authState.loginData.usrRole ?? "No Role",
                    ),
                    const SizedBox(height: 12),
                    _BottomSheetDetailRow(
                      icon: Icons.business_outlined,
                      text: authState.loginData.brcName ?? "No Branch",
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.all(8),
                width: double.infinity,
                child: ZOutlineButton(
                  isActive: true,
                  height: 45,
                  backgroundHover: Theme.of(context).colorScheme.error,
                  onPressed: _logout,
                  label: Text(AppLocalizations.of(context)!.logout),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Drawer Menu Item Widget
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 15),
      visualDensity: VisualDensity(vertical: -4),
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
      onTap: onTap,
    );
  }
}

// Bottom Sheet Detail Row
class _BottomSheetDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BottomSheetDetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}