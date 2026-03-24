import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/IncomeExpense/project_inc_exp.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/Overview/project_overview.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/bloc/project_tabs_bloc.dart';
import '../../../../Features/Generic/tab_bar.dart';
import '../../../../Features/Other/responsive.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../../../Auth/models/login_model.dart';
import 'Ui/ProjectServices/project_services.dart';


class ProjectTabsView extends StatelessWidget {
  final ProjectsModel? project;
  const ProjectTabsView({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _ProjectTabsMobile(project: project),
      tablet: _ProjectTabsTablet(project: project),
      desktop: _ProjectTabsDesktop(project: project),
    );
  }
}

// Mobile View with Bottom Navigation
class _ProjectTabsMobile extends StatefulWidget {
  final ProjectsModel? project;
  const _ProjectTabsMobile({required this.project});

  @override
  State<_ProjectTabsMobile> createState() => _ProjectTabsMobileState();
}

class _ProjectTabsMobileState extends State<_ProjectTabsMobile> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _bottomNavItems;
  bool _isInitialized = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize only once
    if (!_isInitialized) {
      _initializeTabs();
      _isInitialized = true;
    }
  }

  void _initializeTabs() {
    final tr = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthenticatedState) return;
    final login = authState.loginData;

    _screens = [];
    _bottomNavItems = [];

    if (login.hasPermission(48) ?? false) {
      _screens.add(ProjectOverview(model: widget.project));
      _bottomNavItems.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.info_outline),
          label: tr.overview,
        ),
      );
    }

    if (login.hasPermission(49) ?? false) {
      _screens.add(ProjectServicesView(project: widget.project));
      _bottomNavItems.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.miscellaneous_services_rounded),
          label: tr.services,
        ),
      );
     }
    if (login.hasPermission(50) ?? false) {
      _screens.add(ProjectIncomeExpenseView(project: widget.project));
      _bottomNavItems.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.payments_outlined),
          label: tr.pAndLTitle,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    // Check authentication
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }

    // If not initialized or screens empty, show loading or no access
    if (!_isInitialized || _screens.isEmpty) {
      return _buildNoAccessScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project?.prjName ?? tr.details),
        centerTitle: true,
        elevation: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: color.surface,
          selectedItemColor: color.primary,
          unselectedItemColor: color.onSurface.withValues(alpha: .5),
          showUnselectedLabels: true,
          items: _bottomNavItems,
        ),
      ),
    );
  }

  Widget _buildNoAccessScreen(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project?.prjName ?? tr.details),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts_rounded,
              size: 64,
              color: color.onSurface.withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              tr.accessDenied,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: color.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please contact administrator",
              style: TextStyle(
                fontSize: 14,
                color: color.onSurface.withValues(alpha: .4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tablet View with Enhanced Tab Bar
// Tablet View with ZTabContainer
class _ProjectTabsTablet extends StatelessWidget {
  final ProjectsModel? project;
  const _ProjectTabsTablet({required this.project});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.prjName ?? tr.details),
        centerTitle: false,
        elevation: 0,
      ),
      body: BlocBuilder<ProjectTabsBloc, ProjectTabsState>(
        builder: (context, state) {
          final tabs = <ZTabItem<ProjectTabsName>>[
            if (login.hasPermission(48) ?? false)
              ZTabItem(
                value: ProjectTabsName.overview,
                label: tr.overview,
                icon: Icons.info_outline,
                screen: ProjectOverview(model: project),
              ),
            if (login.hasPermission(49) ?? false)
              ZTabItem(
                value: ProjectTabsName.services,
                label: tr.services,
                icon: Icons.build,
                screen: ProjectServicesView(project: project),
              ),
            if (login.hasPermission(50) ?? false)
              ZTabItem(
                value: ProjectTabsName.incomeExpense,
                label: tr.incomeAndExpenses,
                icon: Icons.payments_outlined,
                screen: ProjectIncomeExpenseView(project: project),
              ),
          ];

          if (tabs.isEmpty) {
            return _buildNoAccessScreen(context);
          }

          final available = tabs.map((t) => t.value).toList();
          final selected = available.contains(state.tabs)
              ? state.tabs
              : tabs.first.value;

          return ZTabContainer<ProjectTabsName>(
            /// Tab data
            tabs: tabs,
            selectedValue: selected,

            /// Bloc update
            onChanged: (val) => context
                .read<ProjectTabsBloc>()
                .add(ProjectTabOnChangedEvent(val)),

            /// Colors for rounded style
            style: ZTabStyle.rounded,
            tabBarPadding: const EdgeInsets.symmetric(vertical: 8),
            borderRadius: 0,
            selectedColor: Theme.of(context).colorScheme.primary,
            unselectedTextColor: Theme.of(context).colorScheme.onSurface,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            tabContainerColor: Theme.of(context).colorScheme.surface,
            margin: const EdgeInsets.symmetric(horizontal: 4),

          );
        },
      ),
    );
  }

  Widget _buildNoAccessScreen(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_accounts_rounded,
            size: 72,
            color: color.onSurface.withValues(alpha: .3),
          ),
          const SizedBox(height: 16),
          Text(
            tr.accessDenied,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: color.onSurface.withValues(alpha: .5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please contact administrator",
            style: TextStyle(
              fontSize: 16,
              color: color.onSurface.withValues(alpha: .4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

// Desktop View with ZTabContainer
class _ProjectTabsDesktop extends StatelessWidget {
  final ProjectsModel? project;
  const _ProjectTabsDesktop({required this.project});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;

    return Scaffold(
      body: BlocBuilder<ProjectTabsBloc, ProjectTabsState>(
        builder: (context, state) {
          final tabs = <ZTabItem<ProjectTabsName>>[
            if (login.hasPermission(48) ?? false)
              ZTabItem(
                value: ProjectTabsName.overview,
                label: tr.overview,
                screen: ProjectOverview(model: project),
              ),
            if (login.hasPermission(49) ?? false)
              ZTabItem(
                value: ProjectTabsName.services,
                label: tr.services,
                screen: ProjectServicesView(project: project),
              ),
            if (login.hasPermission(50) ?? false)
              ZTabItem(
                value: ProjectTabsName.incomeExpense,
                label: tr.incomeAndExpenses,
                screen: ProjectIncomeExpenseView(project: project),
              ),
          ];

          if (tabs.isEmpty) {
            return _buildNoAccessDesktop(context);
          }

          final available = tabs.map((t) => t.value).toList();
          final selected = available.contains(state.tabs)
              ? state.tabs
              : tabs.first.value;

          return ZTabContainer<ProjectTabsName>(
            tabs: tabs,
            selectedValue: selected,
            onChanged: (val) => context
                .read<ProjectTabsBloc>()
                .add(ProjectTabOnChangedEvent(val)),
            style: ZTabStyle.rounded,
            tabBarPadding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
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

  Widget _buildNoAccessDesktop(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_accounts_rounded,
            size: 64,
            color: color.onSurface.withValues(alpha: .3),
          ),
          const SizedBox(height: 16),
          Text(
            tr.accessDenied,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: color.onSurface.withValues(alpha: .5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please contact administrator",
            style: TextStyle(
              fontSize: 14,
              color: color.onSurface.withValues(alpha: .4),
            ),
          ),
        ],
      ),
    );
  }
}
