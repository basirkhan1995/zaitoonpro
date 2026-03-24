import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/permission_settings_bloc.dart';
import 'model/permission_settings_model.dart';

class PermissionSettingsView extends StatelessWidget {
  const PermissionSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: const _Mobile(),
        tablet: const _Tablet(),
        desktop: const _Desktop(),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const _PermissionSettingsContent(layoutType: LayoutType.mobile);
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return const _PermissionSettingsContent(layoutType: LayoutType.tablet);
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return const _PermissionSettingsContent(layoutType: LayoutType.desktop);
  }
}

enum LayoutType { mobile, tablet, desktop }

// Permission Category Model
class PermissionCategory {
  final String name;
  final IconData icon;
  final List<String> permissionNames;

  PermissionCategory({
    required this.name,
    required this.icon,
    required this.permissionNames,
  });
}

class _PermissionSettingsContent extends StatefulWidget {
  final LayoutType layoutType;
  const _PermissionSettingsContent({required this.layoutType});

  @override
  State<_PermissionSettingsContent> createState() => _PermissionSettingsContentState();
}

class _PermissionSettingsContentState extends State<_PermissionSettingsContent> {
  final Map<int, Map<String, bool>> _localChanges = {};
  bool _hasChanges = false;
  List<UserRolePermissionSettingModel>? _originalRoles;
  String usrName = '';

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        usrName = authState.loginData.usrName ?? "";
      }
      context.read<PermissionSettingsBloc>().add(LoadPermissionsSettingsEvent());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionSettingsBloc, PermissionSettingsState>(
      builder: (context, state) {
        if (state is PermissionSettingsLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PermissionSettingsErrorState) {
          return _buildErrorState(context, state);
        }

        if (state is PermissionSettingsLoadedState) {
          _originalRoles ??= state.permissions;

          return Stack(
            children: [
              _buildContent(context, state.permissions),
              if (_hasChanges) _buildSaveBar(context),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // Get permission categories
  List<PermissionCategory> _getPermissionCategories(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return [
      PermissionCategory(
        name: locale.dashboard,
        icon: Icons.add_home_outlined,
        permissionNames: [
          "Dashboard",
          "Counts",
          "Exchange Rate Graph",
          "Daily Transactions Graph",
          "Daily Transaction Totals",
          "Digital Clock",
          "Exchange Rates",
          "Profit Loss Graph",
          "Reminder Notifications",
        ],
      ),
      PermissionCategory(
        name: locale.finance,
        icon: Icons.money,
        permissionNames: [
          "Finance",
          "Currency Tab",
          "Currency",
          "Exchange rates",
          "GL Accounts",
          "Payroll",
          "EOY Operation",
          "Reminders",
        ],
      ),
      PermissionCategory(
        name: locale.journal,
        icon: Icons.menu_book_rounded,
        permissionNames: [
          "Journal",
          "All Transactions",
          "Authorized Transaction",
          "Pending Transaction",
          "Cash Deposit",
          "Cash Withdraw",
          "Income Entry",
          "Expense Entry",
          "GL Debit",
          "GL Credit",
          "FT Single Account",
          "FT Multi Account",
          "FX Transactions",
        ],
      ),
      PermissionCategory(
        name: locale.stakeholders,
        icon: Icons.people,
        permissionNames: [
          "Stakeholders",
          "Individuals",
          "Accounts",
          "Users",
        ],
      ),
      PermissionCategory(
        name: locale.hrTitle,
        icon: Icons.person,
        permissionNames: [
          "HR - Human Resource",
          "Employees",
          "Attendance",
          "All Users",
          "Overview",
          "Permissions",
          "User Log",
        ],
      ),
      PermissionCategory(
        name: locale.transport,
        icon: Icons.local_shipping,
        permissionNames: [
          "Transport",
          "Shipping",
          "Drivers",
          "Vehicles",
        ],
      ),
      // PermissionCategory(
      //   name: locale.projects,
      //   icon: Icons.assignment,
      //   permissionNames: [
      //     "Projects",
      //     "New Project",
      //     "Modify Project",
      //     "Project Services",
      //     "Project Payments",
      //   ],
      // ),
      PermissionCategory(
        name: locale.inventory,
        icon: Icons.inventory,
        permissionNames: [
          "Inventory",
          "Orders Tab",
          "Estimate Tab",
          "Goods Shift Tab",
          "Adjustment Tab",
          "Purchase",
          "Sale",
          "Estimate",
          "Goods Shift",
          "Adjustment",
          "Find Invoice",
        ],
      ),
      PermissionCategory(
        name: locale.settings,
        icon: Icons.settings,
        permissionNames: [
          "Settings",
          "General Tab",
          "System Settings",
          "Password Change",
          "User Profile",
          "Roles and Permissions",
          "Company Tab",
          "Profile",
          "Branches",
          "Storage",
          "Transaction Type",
          "Stock",
          "Products",
          "Category",
          "Backup",
          "About",
        ],
      ),
      PermissionCategory(
        name: locale.reports,
        icon: Icons.bar_chart,
        permissionNames: [
          "Reports",
          "Account Statement Single Date",
          "GL Statement Single Date",
          "GL Statement Periodic Date",
          "Creditors",
          "Debtors",
          "Stock Availability",
          "Product Movement",
          "Purchase Invoices",
          "Sale Invoices",
          "Estimate",
          "Goods Shift",
          "Adjustment",
          "All Invoices",
          "Cash Balance All Branch",
          "Cash Balance Single Branch",
          "Exchange Rates",
          "Trial Balance",
          "Transaction Details",
          "Transactions Report",
          "All Balances",
          "Users",
          "User Role and Permission",
          "User Log",
          "Shippings",
          "Vehicles",
          "Drivers",
          "Stakeholders",
          "Employees",
          "Stakeholder Account",
          "GL Accounts",
          "Currencies",
          "Attendance",
          "Reminders",
          "Payroll",
          "Balance Sheet",
         // "All Projects",
         // "Project Services Reports",
        ],
      ),
      PermissionCategory(
        name: locale.actions,
        icon: Icons.touch_app,
        permissionNames: [
          "Create",
          "Read",
          "Update",
          "Delete",
        ],
      ),
    ];
  }

  // Check if permission exists in any role
  bool _permissionExists(List<UserRolePermissionSettingModel> roles, String permissionName) {
    for (var role in roles) {
      if (role.permissions?.any((p) => p.rsgName == permissionName) == true) {
        return true;
      }
    }
    return false;
  }

  Widget _buildContent(BuildContext context, List<UserRolePermissionSettingModel> roles) {
    if (roles.isEmpty) {
      return _buildEmptyState(context);
    }

    final categories = _getPermissionCategories(context);

    switch (widget.layoutType) {
      case LayoutType.mobile:
        return _buildMobileLayout(context, roles, categories);
      case LayoutType.tablet:
        return _buildTabletLayout(context, roles, categories);
      case LayoutType.desktop:
        return _buildDesktopLayout(context, roles, categories);
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(BuildContext context,
      List<UserRolePermissionSettingModel> roles,
      List<PermissionCategory> categories) {
    return Column(
      children: [
        _buildRoleCards(roles, isHorizontal: true),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              final availablePermissions = category.permissionNames
                  .where((name) => _permissionExists(roles, name))
                  .toList();

              if (availablePermissions.isEmpty) return const SizedBox();

              return _buildMobileCategoryCard(
                context,
                category,
                availablePermissions,
                roles,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategoryCard(
      BuildContext context,
      PermissionCategory category,
      List<String> permissions,
      List<UserRolePermissionSettingModel> roles,
      ) {
    final color = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;

    return ZCover(
      radius: 5,
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: color.primary.withValues(alpha: .1),
            child: Icon(
              category.icon,
              color: color.primary,
              size: 16,
            ),
          ),
          title: Text(
            category.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${permissions.length} ${locale.permissions}'),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: permissions.map((permissionName) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                        child: Text(
                          permissionName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color.primary,
                          ),
                        ),
                      ),
                      ...roles.map((role) {
                        final hasPermission = _getEffectivePermission(role, permissionName);
                        final hasLocalChange = _localChanges.containsKey(role.rolId) &&
                            _localChanges[role.rolId]!.containsKey(permissionName);

                        return ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          contentPadding: const EdgeInsets.only(left: 32, right: 8),
                          onTap: () => _onPermissionChanged(role.rolId!, permissionName, !hasPermission),
                          leading: _buildBeautifulStatusIndicator(hasPermission, small: true),
                          title: Text(
                            role.rolName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: hasLocalChange ? FontWeight.bold : FontWeight.normal,
                              color: hasLocalChange ? Colors.orange.shade800 : null,
                            ),
                          ),
                          trailing: hasLocalChange
                              ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 10),
                          )
                              : null,
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout(BuildContext context,
      List<UserRolePermissionSettingModel> roles,
      List<PermissionCategory> categories) {
    return Column(
      children: [
        _buildRoleCards(roles, isHorizontal: true),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildDesktopTable(context, roles, categories),
          ),
        ),
      ],
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(BuildContext context,
      List<UserRolePermissionSettingModel> roles,
      List<PermissionCategory> categories) {
    return Column(
      children: [
        _buildRoleCards(roles, isHorizontal: true),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildDesktopTable(context, roles, categories),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context,
      List<UserRolePermissionSettingModel> roles,
      List<PermissionCategory> categories) {
    final color = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: color.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: color.surface.withValues(alpha: .3)),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.permissions.toUpperCase(),
                    style: TextStyle(
                      color: color.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...roles.map((role) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: color.surface.withValues(alpha: .3)),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            role.rolName?.toUpperCase() ?? 'UNKNOWN',
                            style: TextStyle(
                              color: color.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                          if (_localChanges.containsKey(role.rolId))
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, categoryIndex) {
                final category = categories[categoryIndex];

                final availablePermissions = category.permissionNames
                    .where((name) => _permissionExists(roles, name))
                    .toList();

                if (availablePermissions.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      color: color.primary.withValues(alpha: .1),
                      child: Row(
                        children: [
                          Icon(category.icon, size: 18, color: color.primary),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${availablePermissions.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: color.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Permissions
                    ...availablePermissions.map((permissionName) {
                      return Container(
                        color: color.surface,
                        child: Row(
                          children: [
                            // Permission name cell
                            Container(
                              width: 280,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(
                                permissionName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Status cells
                            ...roles.map((role) {
                              final hasPermission = _getEffectivePermission(role, permissionName);
                              final hasLocalChange = _localChanges.containsKey(role.rolId) &&
                                  _localChanges[role.rolId]!.containsKey(permissionName);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _onPermissionChanged(role.rolId!, permissionName, !hasPermission),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    color: hasLocalChange
                                        ? Colors.orange.withValues(alpha: .05)
                                        : null,
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _buildBeautifulStatusIndicator(hasPermission, small: true),
                                          if (hasLocalChange)
                                            Positioned(
                                              top: -8,
                                              right: -8,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.orange,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.edit,
                                                  color: color.surface,
                                                  size: 8,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REUSABLE COMPONENTS ====================
  Widget _buildRoleCards(List<UserRolePermissionSettingModel> roles, {required bool isHorizontal}) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: roles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildRoleCard(roles[index], index),
          );
        },
      ),
    );
  }

  Widget _buildRoleCard(UserRolePermissionSettingModel role, int index) {
    final effectiveEnabled = _getEffectiveEnabledCount(role);
    final totalPermissions = role.permissions?.length ?? 0;
    final hasChanges = _localChanges.containsKey(role.rolId);
    final color = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showRoleActions(context, role),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getRoleColor(index),
              _getRoleColor(index).withValues(alpha: .7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: _getRoleColor(index).withValues(alpha: .3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.rolName ?? 'Unknown',
                        style: TextStyle(
                          color: color.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasChanges)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: color.surface,
                          size: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$effectiveEnabled / $totalPermissions ${AppLocalizations.of(context)!.permissions}',
                  style: TextStyle(
                    color: color.surface.withValues(alpha: .8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeautifulStatusIndicator(bool hasPermission, {bool small = false}) {
    if (small) {
      return Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasPermission
              ? Colors.green.shade50
              : Colors.red.shade50,
          border: Border.all(
            color: hasPermission
                ? Colors.green.shade200
                : Colors.red.shade200,
            width: 1,
          ),
        ),
        child: Icon(
          hasPermission ? Icons.check_circle : Icons.remove_circle,
          color: hasPermission ? Colors.green.shade700 : Colors.red.shade400,
          size: 17,
        ),
      );
    }

    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasPermission
            ? Colors.green.shade50
            : Colors.red.shade50,
        border: Border.all(
          color: hasPermission
              ? Colors.green.shade200
              : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Icon(
        hasPermission ? Icons.check_circle : Icons.remove_circle,
        color: hasPermission ? Colors.green.shade700 : Colors.red.shade400,
        size: 18,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PermissionSettingsErrorState state) {
    return Center(
        child: NoDataWidget(
          title: "Error",
          message: "Failed to load permissions, try again later",
          onRefresh: () => context.read<PermissionSettingsBloc>().add(LoadPermissionsSettingsEvent()),
        )
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
        child: NoDataWidget(
          title: "No Role found",
          message: "Failed to load permissions, try again later",
          onRefresh: () => context.read<PermissionSettingsBloc>().add(LoadPermissionsSettingsEvent()),
        )
    );
  }

  Widget _buildSaveBar(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Positioned(
      bottom: 20,
      left: isMobile ? 16 : 0,
      right: isMobile ? 16 : 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 16 : 12
          ),
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: isMobile
              ? _buildMobileSaveBar(color)
              : _buildDesktopSaveBar(color),
        ),
      ),
    );
  }

  Widget _buildDesktopSaveBar(ColorScheme color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info, color: Colors.blue.shade700),
        const SizedBox(width: 5),
        Text(
          'You have unsaved changes',
          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        ZOutlineButton(
          onPressed: _cancelChanges,
          isActive: true,
          backgroundHover: color.error,
          label: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ZOutlineButton(
          onPressed: _saveAllChanges,
          isActive: true,
          label: const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildMobileSaveBar(ColorScheme color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.info, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You have unsaved changes',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ZOutlineButton(
                onPressed: _cancelChanges,
                isActive: true,
                backgroundHover: color.error,
                label: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ZOutlineButton(
                onPressed: _saveAllChanges,
                isActive: true,
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== EXISTING METHODS ====================
  void _onPermissionChanged(int roleId, String permissionName, bool newValue) {
    setState(() {
      _localChanges.putIfAbsent(roleId, () => {});
      _localChanges[roleId]![permissionName] = newValue;
      _hasChanges = true;
    });
  }

  void _cancelChanges() {
    setState(() {
      _localChanges.clear();
      _hasChanges = false;
    });
  }

  void _saveAllChanges() {
    if (!_hasChanges || _originalRoles == null) return;

    final List<PermissionActions> permissionUpdates = [];

    _localChanges.forEach((roleId, permissionChanges) {
      permissionChanges.forEach((permissionName, newStatus) {
        final originalRole = _originalRoles!.firstWhere(
              (r) => r.rolId == roleId,
          orElse: () => UserRolePermissionSettingModel(rolId: roleId),
        );

        final permission = originalRole.permissions?.firstWhere(
              (p) => p.rsgName == permissionName,
          orElse: () => UsrPermission(rsgName: permissionName),
        );

        if (permission?.rpId != null) {
          permissionUpdates.add(
            PermissionActions(
              rpId: permission!.rpId,
              rpStatus: newStatus ? 1 : 0,
            ),
          );
        }
      });
    });

    if (permissionUpdates.isNotEmpty) {
      final updateModel = PermissionActionModel(
        usrName: usrName,
        permissions: permissionUpdates,
      );

      context.read<PermissionSettingsBloc>().add(
          UpdatePermissionsSettingsEvent(updateModel)
      );

      setState(() {
        _localChanges.clear();
        _hasChanges = false;
      });
    }
  }

  bool _getEffectivePermission(UserRolePermissionSettingModel role, String permissionName) {
    if (_localChanges.containsKey(role.rolId) && _localChanges[role.rolId]!.containsKey(permissionName)) {
      return _localChanges[role.rolId]![permissionName]!;
    }

    if (role.permissions == null) return false;
    final permission = role.permissions!.firstWhere(
          (p) => p.rsgName == permissionName,
      orElse: () => UsrPermission(rpStatus: 0),
    );
    return permission.rpStatus == 1;
  }

  void _showRoleActions(BuildContext context, UserRolePermissionSettingModel role) {
    final tr = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.privacy_tip_rounded),
                const SizedBox(width: 8),
                Text(
                  role.rolName ?? tr.roleActions,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(tr.grantAll),
              onTap: () {
                Navigator.pop(context);
                _enableAllForRole(role.rolId!);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text(tr.revokeAll),
              onTap: () {
                Navigator.pop(context);
                _disableAllForRole(role.rolId!);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: Text(tr.restoreDefault),
              onTap: () {
                Navigator.pop(context);
                _resetRoleChanges(role.rolId!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _enableAllForRole(int roleId) {
    final role = _originalRoles?.firstWhere((r) => r.rolId == roleId);
    if (role?.permissions != null) {
      for (var permission in role!.permissions!) {
        if (permission.rsgName != null) {
          _onPermissionChanged(roleId, permission.rsgName!, true);
        }
      }
    }
  }

  void _disableAllForRole(int roleId) {
    final role = _originalRoles?.firstWhere((r) => r.rolId == roleId);
    if (role?.permissions != null) {
      for (var permission in role!.permissions!) {
        if (permission.rsgName != null) {
          _onPermissionChanged(roleId, permission.rsgName!, false);
        }
      }
    }
  }

  void _resetRoleChanges(int roleId) {
    setState(() {
      _localChanges.remove(roleId);
      _hasChanges = _localChanges.isNotEmpty;
    });
  }

  int _getEffectiveEnabledCount(UserRolePermissionSettingModel role) {
    if (!_localChanges.containsKey(role.rolId)) {
      return role.permissions?.where((p) => p.rpStatus == 1).length ?? 0;
    }

    final changes = _localChanges[role.rolId]!;
    return role.permissions?.fold(0, (sum, p) {
      final currentStatus = changes.containsKey(p.rsgName) ? changes[p.rsgName]! : p.rpStatus == 1;
      return sum! + (currentStatus ? 1 : 0);
    }) ?? 0;
  }

  Color _getRoleColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange
    ];
    return colors[index % colors.length];
  }
}