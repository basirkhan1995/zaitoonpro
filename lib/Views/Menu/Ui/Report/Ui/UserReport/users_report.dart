import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/user_details.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/model/usr_report_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/UserReport/status_drop.dart';
import '../../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../HR/Ui/Users/bloc/users_bloc.dart';
import '../../../Settings/Ui/General/Ui/UserRole/features/role_drop.dart';

class UsersReportView extends StatelessWidget {
  const UsersReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  int? role;
  int? branchId;
  int? status;

  final _filterRoleController = TextEditingController();
  final _filterBranchController = TextEditingController();

  bool get isFilterActive => role != null || branchId != null || status != null;

  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(ResetUserEvent());
  }

  @override
  void dispose() {
    _filterRoleController.dispose();
    _filterBranchController.dispose();
    super.dispose();
  }

  void onApply() {
    context.read<UsersBloc>().add(
      LoadUsersReportEvent(
        status: status,
        role: role,
        branchId: branchId,
      ),
    );
  }

  void onClearFilters() {
    setState(() {
      role = null;
      branchId = null;
      status = null;
      _filterRoleController.clear();
      _filterBranchController.clear();
    });
    context.read<UsersBloc>().add(ResetUserEvent());
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;
    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      estimatedContentHeight: 400,
      initialChildSize: 0.65,
      bodyBuilder: (context, controller) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: controller,
              children: [
                const SizedBox(height: 4),

                // Role Dropdown
                UserRoleDropdown(
                  title: tr.userRole,
                  showAllOption: true,
                  onRoleSelected: (e) {
                    setSheetState(() => role = e?.rolId);
                  },
                ),
                const SizedBox(height: 12),

                // Branch Dropdown
                BranchDropdown(
                  showAllOption: true,
                  onBranchSelected: (e) {
                    setSheetState(() => branchId = e?.brcId);
                  },
                ),
                const SizedBox(height: 12),

                // Status Dropdown
                StatusDropdown(
                  value: status,
                  onChanged: (v) {
                    setSheetState(() => status = v);
                  },
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    if (isFilterActive)
                      Expanded(
                        child: ZOutlineButton(
                          onPressed: () {
                            setSheetState(() {
                              role = null;
                              branchId = null;
                              status = null;
                              _filterRoleController.clear();
                              _filterBranchController.clear();
                            });
                            setState(() {});
                          },
                          label: Text(tr.clear),
                        ),
                      ),
                    if (isFilterActive) const SizedBox(width: 8),
                    Expanded(
                      child: ZOutlineButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onApply();
                        },
                        isActive: true,
                        label: Text(tr.apply),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("${tr.users} ${tr.report}"),
        actionsPadding: EdgeInsets.all(5),
        actions: [
          if (isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: onClearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected Filters Chips
          if (isFilterActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (role != null)
                      _buildFilterChip(
                        label: "${tr.usrRole}: $role",
                        color: color.primary,
                        onRemove: () {
                          setState(() {
                            role = null;
                          });
                          if (!isFilterActive) {
                            context.read<UsersBloc>().add(ResetUserEvent());
                          }
                        },
                      ),
                    if (branchId != null)
                      _buildFilterChip(
                        label: "${tr.branch}: $branchId",
                        color: color.secondary,
                        onRemove: () {
                          setState(() {
                            branchId = null;
                          });
                          if (!isFilterActive) {
                            context.read<UsersBloc>().add(ResetUserEvent());
                          }
                        },
                      ),
                    if (status != null)
                      _buildFilterChip(
                        label: "${tr.status}: ${status == 1 ? tr.active : tr.inactive}",
                        color: status == 1 ? Colors.green : color.error,
                        onRemove: () {
                          setState(() {
                            status = null;
                          });
                          if (!isFilterActive) {
                            context.read<UsersBloc>().add(ResetUserEvent());
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state is UsersLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is UsersInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "${tr.users} ${tr.report}",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr.usersHintReport,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color.outline),
                        ),
                        const SizedBox(height: 24),
                        ZOutlineButton(
                          onPressed: _showFilterBottomSheet,
                          icon: Icons.filter_list,
                          label: Text(tr.apply),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UsersErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: color.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(color: color.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: onApply,
                            icon: const Icon(Icons.refresh),
                            label: Text(tr.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is UsersReportLoadedState) {
                  if (state.users.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final usr = state.users[index];
                      return _buildMobileUserCard(usr, index, color, tr);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileUserCard(UsersReportModel usr, int index, ColorScheme color, AppLocalizations tr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.outline.withValues(alpha: .1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: index.isOdd ? color.primary.withValues(alpha: .02) : color.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      usr.createDate.toFormattedDate(),
                      style: TextStyle(
                        color: color.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: usr.status?.toLowerCase() == 'active'
                          ? Colors.green.withValues(alpha: .1)
                          : color.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      usr.status ?? "",
                      style: TextStyle(
                        color: usr.status?.toLowerCase() == 'active'
                            ? Colors.green
                            : color.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Username and Email
              Text(
                usr.username ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                usr.email ?? "",
                style: TextStyle(
                  fontSize: 13,
                  color: color.outline,
                ),
              ),
              const SizedBox(height: 8),

              // Full Name
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: color.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usr.fullName ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Role and Branch
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.work,
                          size: 14,
                          color: color.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            usr.role ?? "",
                            style: TextStyle(
                              fontSize: 13,
                              color: color.outline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.business,
                          size: 14,
                          color: color.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            usr.branch.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: color.outline,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // ALF, FCP, Verification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip('alf', usr.alf?.toString() ?? "0", Colors.blue, color),
                  _buildInfoChip(tr.fcp, usr.fcp ?? "-", Colors.purple, color),
                  _buildInfoChip(tr.verified, usr.verification ?? "-", Colors.orange, color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color chipColor, ColorScheme color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: chipColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  int? roleId;
  int? branchId;
  int? status;
  bool _showFilters = true;

  bool get isFilterActive => roleId != null || branchId != null || status != null;

  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(ResetUserEvent());
  }

  void onApply() {
    context.read<UsersBloc>().add(
      LoadUsersReportEvent(
        status: status,
        role: roleId,
        branchId: branchId,
      ),
    );
  }

  void onClearFilters() {
    setState(() {
      roleId = null;
      branchId = null;
      status = null;
    });
    context.read<UsersBloc>().add(ResetUserEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color.surface,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("${tr.users} ${tr.report}"),
        actionsPadding: EdgeInsets.symmetric(horizontal: 8),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (isFilterActive)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: onClearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: onApply,
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Role
                  SizedBox(
                    width: 200,
                    child: UserRoleDropdown(
                      title: tr.userRole,
                      showAllOption: true,
                      onRoleSelected: (e) {
                        setState(() => roleId = e?.rolId);
                      },
                    ),
                  ),
                  // Branch
                  SizedBox(
                    width: 200,
                    child: BranchDropdown(
                      showAllOption: true,
                      onBranchSelected: (e) {
                        setState(() => branchId = e?.brcId);
                      },
                    ),
                  ),
                  // Status
                  SizedBox(
                    width: 150,
                    child: StatusDropdown(
                      value: status,
                      onChanged: (v) {
                        setState(() => status = v);
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text(tr.date, style: titleStyle)),
                Expanded(child: Text(tr.username, style: titleStyle)),
                SizedBox(width: 150, child: Text(tr.userOwner, style: titleStyle)),
                SizedBox(width: 100, child: Text(tr.usrRole, style: titleStyle)),
                SizedBox(width: 70, child: Text(tr.branch, style: titleStyle)),
                SizedBox(width: 60, child: Text("ALF", style: titleStyle)),
                SizedBox(width: 60, child: Text(tr.fcp, style: titleStyle)),
                SizedBox(width: 70, child: Text(tr.verified, style: titleStyle)),
                SizedBox(width: 70, child: Text(tr.status, style: titleStyle)),
              ],
            ),
          ),

          // Data Rows
          Expanded(
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state is UsersLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is UsersInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "${tr.users} ${tr.report}",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr.usersHintReport,
                          style: TextStyle(color: color.outline),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UsersErrorState) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: color.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(color: color.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: onApply,
                          icon: const Icon(Icons.refresh),
                          label: Text(tr.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UsersReportLoadedState) {
                  if (state.users.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final usr = state.users[index];
                      final isEven = index.isEven;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isEven ? color.primary.withValues(alpha: .02) : Colors.transparent,
                          border: index == 0
                              ? null
                              : Border(
                            top: BorderSide(color: color.outline.withValues(alpha: .1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Date
                            SizedBox(
                              width: 100,
                              child: Text(
                                usr.createDate.toFormattedDate(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),

                            // User Information
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    usr.username ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    usr.email ?? "",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color.outline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Full Name
                            SizedBox(
                              width: 150,
                              child: Text(
                                usr.fullName ?? "",
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Role
                            SizedBox(
                              width: 100,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.secondary.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  usr.role ?? "",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color.secondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Branch
                            SizedBox(
                              width: 70,
                              child: Text(
                                usr.branch.toString(),
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // ALF
                            SizedBox(
                              width: 60,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  usr.alf?.toString() ?? "0",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // FCP
                            SizedBox(
                              width: 60,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  usr.fcp ?? "-",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.purple,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Verification
                            SizedBox(
                              width: 70,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  usr.verification ?? "-",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Status
                            SizedBox(
                              width: 70,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: usr.status?.toLowerCase() == 'active'
                                      ? Colors.green.withValues(alpha: .1)
                                      : color.error.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  usr.status ?? "",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: usr.status?.toLowerCase() == 'active'
                                        ? Colors.green
                                        : color.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController searchController = TextEditingController();

  int? role;
  int? branchId;
  int? status;

  /// 🔹 Derived state (NO stored bool)
  bool get isFilterActive => role != null || branchId != null || status != null;



  void onApply() {
    context.read<UsersBloc>().add(
      LoadUsersReportEvent(
        status: status,
        role: role,
        branchId: branchId,
      ),
    );
  }

  void onClearFilters() {
    setState(() {
      role = null;
      branchId = null;
      status = null;
    });

    context.read<UsersBloc>().add(ResetUserEvent());
  }

  @override
  void initState() {
    context.read<UsersBloc>().add(ResetUserEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.surface);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("${tr.users} ${tr.report}"),
        actionsPadding: EdgeInsets.symmetric(horizontal: 8),
        actions: [
          /// 🔹 CLEAR FILTERS (only when active)
          if (isFilterActive)...[
            ZOutlineButton(
              backgroundHover: Theme.of(context).colorScheme.error,
              isActive: true,
              icon: Icons.filter_alt_off,
              onPressed: onClearFilters,
              label: Text(tr.clearFilters),
            ),
            SizedBox(width: 8),
          ],


          /// 🔹 APPLY BUTTON
          ZOutlineButton(

            isActive: true,
            icon: Icons.filter_alt,
            onPressed: onApply,
            label: Text(tr.apply),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 FILTER BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                 // const Expanded(flex: 3, child: SizedBox()),

                  Expanded(
                    child: UserRoleDropdown(
                      title: tr.userRole,
                      showAllOption: true,
                      onRoleSelected: (e) {
                        setState(() => role = e?.rolId);
                      },
                    ),
                  ),

                  Expanded(
                    child: BranchDropdown(
                      title: tr.branches,
                      showAllOption: true,
                      onBranchSelected: (e) {
                        setState(() => branchId = e?.brcId);
                      },
                    ),
                  ),

                  Expanded(
                    child: StatusDropdown(
                      value: status,
                      onChanged: (v) {
                        setState(() => status = v);
                      },
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.symmetric(vertical: 8,horizontal: 8),
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .8),
              ),
              child: Row(
                children: [
                 SizedBox(
                     width: 100,
                     child: Text(tr.date,style: titleStyle)),
                  Expanded(
                      child: Text(tr.userInformation,style: titleStyle)),
                  SizedBox(
                      width: 180,
                      child: Text(tr.userOwner,style: titleStyle)),
                  SizedBox(
                      width: 120,
                      child: Text(tr.usrRole,style: titleStyle)),
                  SizedBox(
                      width: 80,
                      child: Text(tr.branch,style: titleStyle)),
                  SizedBox(
                      width: 80,
                      child: Text("ALF",style: titleStyle)),
                  SizedBox(
                      width: 80,
                      child: Text(tr.fcp,style: titleStyle)),
                  SizedBox(
                      width: 80,
                      child: Text(tr.verified,style: titleStyle)),
                  SizedBox(
                      width: 80,
                      child: Text(tr.status,style: titleStyle)),

                ],
              ),
            ),

            /// 🔹 DATA AREA
            Expanded(
              child: BlocBuilder<UsersBloc, UsersState>(
                builder: (context, state) {
                  if (state is UsersLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is UsersInitial) {
                    return NoDataWidget(
                      title: "${tr.users} ${tr.report}",
                      message: tr.usersHintReport,
                      enableAction: false,
                    );
                  }

                  if (state is UsersErrorState) {
                    return NoDataWidget(
                      message: state.message,
                      onRefresh: onApply,
                    );
                  }

                  if (state is UsersReportLoadedState) {

                    return ListView.builder(
                        itemCount: state.users.length,
                        itemBuilder: (context,index){
                          final usr = state.users[index];
                        return InkWell(
                          onTap: (){
                            showDialog(context: context, builder: (context){
                              return UserDetailsView(usr: usr.toUsersModel());
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8,vertical: 8),
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: index.isEven? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 100,
                                    child: Text(usr.createDate.toFormattedDate())),
                                Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(usr.username??"",style: Theme.of(context).textTheme.titleSmall),
                                        Text(usr.email??"",style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),),
                                      ],
                                    )),
                                SizedBox(
                                    width: 180,
                                    child: Text(usr.fullName??"")),

                                SizedBox(
                                    width: 120,
                                    child: Text(usr.role??"")),
                                SizedBox(
                                    width: 80,
                                    child: Text(usr.branch.toString())),
                                SizedBox(
                                    width: 80,
                                    child: Text(usr.alf.toString())),

                                SizedBox(
                                    width: 80,
                                    child: Text(usr.fcp??"")),
                                SizedBox(
                                    width: 80,
                                    child: Text(usr.verification??"")),
                                SizedBox(
                                    width: 80,
                                    child: Text(usr.status??"")),
                              ],
                            ),
                          ),
                        );
                    });
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
