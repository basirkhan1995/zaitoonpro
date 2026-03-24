import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/blur_loading.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Permissions/per_model.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Users/model/user_model.dart';
import 'bloc/permissions_bloc.dart';

class PermissionsView extends StatelessWidget {
  final UsersModel user;
  const PermissionsView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _PermissionsContent(user: user),
      tablet: _PermissionsContent(user: user),
      desktop: _PermissionsContent(user: user),
    );
  }
}

class _PermissionsContent extends StatefulWidget {
  final UsersModel user;
  const _PermissionsContent({required this.user});

  @override
  State<_PermissionsContent> createState() => _PermissionsContentState();
}

class _PermissionsContentState extends State<_PermissionsContent> {
  // Track local changes
  final Map<int, bool> _localChanges = {};
  bool _hasChanges = false;

  @override
  void initState() {
    context.read<PermissionsBloc>().add(
      LoadPermissionsEvent(widget.user.usrName ?? ""),
    );
    super.initState();
  }

  void _onPermissionChanged(int uprRole, bool newValue) {
    setState(() {
      _localChanges[uprRole] = newValue;
      _hasChanges = true;
    });
  }

  void _saveAllChanges() {
    if (!_hasChanges) return;

    final permissions = _localChanges.entries.map((entry) {
      return {
        "uprRole": entry.key,
        "uprStatus": entry.value ? 1 : 0, // Convert bool to int HERE
      };
    }).toList();

    context.read<PermissionsBloc>().add(
      UpdatePermissionsEvent(
        usrName: widget.user.usrName ?? "",
        usrId: widget.user.usrId!,
        permissions: permissions, // permissions now have int values
      ),
    );

    setState(() {
      _localChanges.clear();
      _hasChanges = false;
    });
  }

  void _cancelChanges() {
    setState(() {
      _localChanges.clear();
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    // Complete permission groups based on the provided list (rpID 1-119)
    final List<PermissionCategory> categories = [
      PermissionCategory(
        name: locale.dashboard,
        icon: Icons.dashboard,
        roleIds: [1, 2, 3, 4, 5, 6, 7, 8, 9],
      ),
      PermissionCategory(
        name: locale.finance,
        icon: Icons.attach_money,
        roleIds: [10, 11, 12, 13, 14, 15, 16, 17],
      ),
      PermissionCategory(
        name: locale.journal,
        icon: Icons.book,
        roleIds: [18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
      ),
      PermissionCategory(
        name: locale.stakeholders,
        icon: Icons.people,
        roleIds: [31, 32, 33, 34],
      ),
      PermissionCategory(
        name: locale.hrTitle,
        icon: Icons.person,
        roleIds: [35, 36, 37, 38, 39, 40, 41],
      ),
      PermissionCategory(
        name: locale.transport,
        icon: Icons.local_shipping,
        roleIds: [42, 43, 44, 45],
      ),
      // PermissionCategory(
      //   name: locale.projects,
      //   icon: Icons.assignment,
      //   roleIds: [46, 47, 48, 49, 50],
      // ),
      PermissionCategory(
        name: locale.inventory,
        icon: Icons.inventory,
        roleIds: [51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61],
      ),
      PermissionCategory(
        name: locale.settings,
        icon: Icons.settings,
        roleIds: [62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77],
      ),
      PermissionCategory(
        name: locale.reports,
        icon: Icons.bar_chart,
        roleIds: [
          78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94,
          95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109,
          110, 111, 112, 113, // 114, 115
        ],
      ),
      PermissionCategory(
        name: locale.actions,
        icon: Icons.touch_app,
        roleIds: [116, 117, 118, 119],
      ),
    ];

    return Scaffold(
      backgroundColor: color.surface,
      floatingActionButton: _hasChanges
          ? Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.small(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              heroTag: locale.cancel,
              onPressed: _cancelChanges,
              backgroundColor: color.errorContainer,
              child: Icon(Icons.close, color: color.error),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              heroTag: locale.saveChanges,
              onPressed: _saveAllChanges,
              backgroundColor: color.primary,
              child: Icon(Icons.check_rounded, color: color.onPrimary),
            ),
          ],
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: BlocBuilder<PermissionsBloc, PermissionsState>(
        builder: (context, state) {
          if (state is PermissionsErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: color.error),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: TextStyle(color: color.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PermissionsBloc>().add(
                          LoadPermissionsEvent(widget.user.usrName ?? ""),
                        );
                      },
                      child: Text(locale.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PermissionsLoadingState) {
            return const Center(
              child: BlurLoader(
                blur: 4,
                isLoading: true,
                child: SizedBox(),
              ),
            );
          }

          if (state is PermissionsLoadedState) {
            // Create a map of permission by uprRole for quick lookup
            final permissionMap = {
              for (var p in state.permissions) p.uprRole: p
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determine number of columns based on screen width
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1400) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 1100) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 700) {
                    crossAxisCount = 2;
                  }

                  return MasonryGrid(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: categories.map((category) {
                      // Get permissions for this category
                      final categoryPermissions = category.roleIds
                          .map((id) => permissionMap[id])
                          .where((p) => p != null)
                          .cast<UserPermissionsModel>()
                          .toList();

                      if (categoryPermissions.isEmpty) return const SizedBox();

                      return _buildCategoryCard(
                        context,
                        category,
                        categoryPermissions,
                      );
                    }).toList(),
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context,
      PermissionCategory category,
      List<UserPermissionsModel> permissions,
      ) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.surface,
        border: Border.all(
          color: color.outline.withValues(alpha: .2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.shadow.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color.outline.withValues(alpha: .2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  size: 18,
                  color: color.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${permissions.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: color.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Permissions List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: permissions.length,
            itemBuilder: (context, index) {
              final permission = permissions[index];
              final hasLocalChange = _localChanges.containsKey(permission.uprRole);
              final currentValue = hasLocalChange
                  ? _localChanges[permission.uprRole]!
                  : permission.uprStatus == 1;

              return InkWell(
                onTap: () {
                  _onPermissionChanged(permission.uprRole!, !currentValue);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hasLocalChange
                        ? color.primary.withValues(alpha: .05)
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      SizedBox(
                        width: 30,
                        child: Checkbox(
                          visualDensity: const VisualDensity(horizontal: -2),
                          value: currentValue,
                          onChanged: (value) {
                            if (value != null) {
                              _onPermissionChanged(
                                permission.uprRole!,
                                value,
                              );
                            }
                          },
                        ),
                      ),

                      // Permission Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permission.rsgName ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: color.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasLocalChange)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  locale.changedTitle,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: currentValue
                              ? Colors.green.withValues(alpha: .1)
                              : Colors.red.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: currentValue ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentValue
                                  ? locale.enableTitle
                                  : locale.disabledTitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: currentValue ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (hasLocalChange) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.pending,
                          size: 14,
                          color: color.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Permission Category Model
class PermissionCategory {
  final String name;
  final IconData icon;
  final List<int> roleIds;

  PermissionCategory({
    required this.name,
    required this.icon,
    required this.roleIds,
  });
}

// Custom Masonry Grid to handle different sized cards
class MasonryGrid extends StatelessWidget {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final List<Widget> children;

  const MasonryGrid({
    super.key,
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final List<List<Widget>> columns = List.generate(crossAxisCount, (_) => []);

    for (int i = 0; i < children.length; i++) {
      columns[i % crossAxisCount].add(children[i]);
      if (i % crossAxisCount != crossAxisCount - 1 && i < children.length - 1) {
        columns[i % crossAxisCount].add(SizedBox(height: mainAxisSpacing));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(crossAxisCount, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : crossAxisSpacing / 2,
              right: index == crossAxisCount - 1 ? 0 : crossAxisSpacing / 2,
            ),
            child: Column(
              children: columns[index],
            ),
          ),
        );
      }),
    );
  }
}