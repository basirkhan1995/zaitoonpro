import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/General/Ui/RolesAndPermissions/bloc/permission_settings_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/General/Ui/RolesAndPermissions/model/permission_settings_model.dart';

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

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Widget _buildContent(BuildContext context, List<UserRolePermissionSettingModel> roles) {
    if (roles.isEmpty) {
      return _buildEmptyState(context);
    }

    // Get all unique permissions
    final allPermissions = _getAllUniquePermissions(roles);

    // Choose layout based on screen size
    switch (widget.layoutType) {
      case LayoutType.mobile:
        return _buildMobileLayout(context, roles, allPermissions);
      case LayoutType.tablet:
        return _buildTabletLayout(context, roles, allPermissions);
      case LayoutType.desktop:
        return _buildDesktopLayout(context, roles, allPermissions);
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(BuildContext context, List<UserRolePermissionSettingModel> roles, List<String> allPermissions) {
    return Column(
      children: [
        // Role cards at top
        _buildRoleCards(roles, isHorizontal: true),
        const SizedBox(height: 16),
        // Expandable permission sections
        Expanded(
          child: _buildMobilePermissionList(roles, allPermissions),
        ),
      ],
    );
  }

  Widget _buildMobilePermissionList(List<UserRolePermissionSettingModel> roles, List<String> allPermissions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: allPermissions.length,
      itemBuilder: (context, index) {
        final permissionName = allPermissions[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              permissionName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                (index + 1).toString(),
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
              ),
            ),
            children: roles.map((role) {
              final hasPermission = _getEffectivePermission(role, permissionName);
              final hasLocalChange = _localChanges.containsKey(role.rolId) &&
                  _localChanges[role.rolId]!.containsKey(permissionName);

              return ListTile(
                onTap: () => _onPermissionChanged(role.rolId!, permissionName, !hasPermission),
                leading: _buildBeautifulStatusIndicator(hasPermission, small: true),
                title: Text(
                  role.rolName ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: hasLocalChange ? FontWeight.bold : FontWeight.normal,
                    color: hasLocalChange ? Colors.orange.shade800 : null,
                  ),
                ),
                trailing: hasLocalChange
                    ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 12),
                )
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout(BuildContext context, List<UserRolePermissionSettingModel> roles, List<String> allPermissions) {
    return Column(
      children: [
        // Role cards at top
        _buildRoleCards(roles, isHorizontal: true),
        const SizedBox(height: 24),
        // Compact table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabletTable(roles, allPermissions),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletTable(List<UserRolePermissionSettingModel> roles, List<String> allPermissions) {
    final color = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: color.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    AppLocalizations.of(context)!.permissions.toUpperCase(),
                    style: TextStyle(
                      color: color.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                ...roles.map((role) => Expanded(
                  child: Center(
                    child: Text(
                      role.rolName?.toUpperCase() ?? '',
                      style: TextStyle(
                        color: color.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )),
              ],
            ),
          ),
          // Body
          Expanded(
            child: ListView.builder(
              itemCount: allPermissions.length,
              itemBuilder: (context, index) {
                final permissionName = allPermissions[index];

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: index.isEven ? Colors.white : Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(
                          permissionName,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...roles.map((role) {
                        final hasPermission = _getEffectivePermission(role, permissionName);
                        final hasLocalChange = _localChanges.containsKey(role.rolId) &&
                            _localChanges[role.rolId]!.containsKey(permissionName);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onPermissionChanged(role.rolId!, permissionName, !hasPermission),
                            child: Center(
                              child: Stack(
                                children: [
                                  _buildBeautifulStatusIndicator(hasPermission, small: true),
                                  if (hasLocalChange)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    'Total: ${allPermissions.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
                ...roles.map((role) {
                  final effectiveEnabled = _getEffectiveEnabledCount(role);
                  final hasChanges = _localChanges.containsKey(role.rolId);

                  return Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasChanges ? Colors.orange.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$effectiveEnabled',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasChanges ? Colors.orange.shade800 : Colors.blue.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(BuildContext context, List<UserRolePermissionSettingModel> roles, List<String> allPermissions) {
    return Column(
      children: [
        // Role cards at top
        _buildRoleCards(roles, isHorizontal: true),
        const SizedBox(height: 10),
        // Expanded table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildDesktopTable(roles, allPermissions),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<UserRolePermissionSettingModel> roles, List<String> allPermissions) {
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
              itemCount: allPermissions.length,
              itemBuilder: (context, index) {
                final permissionName = allPermissions[index];

                return Container(
                  color: index.isEven ? color.surface : color.primary.withValues(alpha: .05),
                  child: Row(
                    children: [
                      // Permission name cell
                      Container(
                        width: 280,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          permissionName,
                          style: const TextStyle(
                            fontSize: 14,
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: hasLocalChange
                                  ? Colors.orange.withValues(alpha: .05)
                                  : null,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _buildBeautifulStatusIndicator(hasPermission),
                                    if (hasLocalChange)
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            color: color.surface,
                                            size: 10,
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
              },
            ),
          ),

          // Elevated footer
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color.surface,
              boxShadow: [
                BoxShadow(
                  color: color.outline.withValues(alpha: .2),
                  blurRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Summary cell
                Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${AppLocalizations.of(context)!.totalTitle}: ${allPermissions.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color.outline.withValues(alpha: .6),
                      fontSize: 13,
                    ),
                  ),
                ),
                // Role totals
                ...roles.map((role) {
                  final effectiveEnabled = _getEffectiveEnabledCount(role);
                  final hasChanges = _localChanges.containsKey(role.rolId);

                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: hasChanges
                                ? [Colors.orange.shade400, Colors.orange.shade600]
                                : [Colors.blue.shade400, Colors.blue.shade600],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '$effectiveEnabled',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REUSABLE COMPONENTS ====================
  Widget _buildRoleCards(List<UserRolePermissionSettingModel> roles, {required bool isHorizontal}) {
    return Container(
      height: 100,
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

    return GestureDetector(
      onTap: () => _showRoleActions(context, role),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getRoleColor(index),
              _getRoleColor(index).withValues(alpha: .7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$effectiveEnabled / $totalPermissions ${AppLocalizations.of(context)!.permissions}',
                  style: const TextStyle(
                    color: Colors.white70,
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
        width: 32,
        height: 32,
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

    return Container(
      width: 40,
      height: 40,
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
        size: 24,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PermissionSettingsErrorState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),
          Text('Failed to load permissions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(state.message, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<PermissionSettingsBloc>().add(LoadPermissionsSettingsEvent()),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_update_warning, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No roles found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: Row(
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
          ),
        ),
      ),
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

    final List<Map<String, dynamic>> updates = [];

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
          updates.add({
            "rpID": permission!.rpId,
            "rpStatus": newStatus ? 1 : 0,
          });
        }
      });
    });

    if (updates.isNotEmpty) {
      setState(() {
        _localChanges.clear();
        _hasChanges = false;
      });

      ///TODO Update event
    ///  ToastManager.show(context: context, message: "Permissions updated successfully", type: ToastType.success);
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
                const Icon(Icons.security_rounded),
                const SizedBox(width: 8),
                Text(
                  role.rolName ?? 'Role Actions',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Enable All Permissions'),
              onTap: () {
                Navigator.pop(context);
                _enableAllForRole(role.rolId!);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Disable All Permissions'),
              onTap: () {
                Navigator.pop(context);
                _disableAllForRole(role.rolId!);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Reset to Original'),
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

  List<String> _getAllUniquePermissions(List<UserRolePermissionSettingModel> roles) {
    final Set<String> uniquePermissions = {};

    for (var role in roles) {
      if (role.permissions != null) {
        for (var permission in role.permissions!) {
          if (permission.rsgName != null && permission.rsgName!.isNotEmpty) {
            uniquePermissions.add(permission.rsgName!);
          }
        }
      }
    }

    return uniquePermissions.toList()..sort();
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
    ];
    return colors[index % colors.length];
  }
}