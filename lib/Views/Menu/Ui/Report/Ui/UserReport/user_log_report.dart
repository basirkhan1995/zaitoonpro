import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Log/bloc/user_log_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Log/model/user_log_model.dart';
import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../HR/Ui/Users/features/date_range_string.dart';
import '../../../HR/Ui/Users/features/users_drop.dart';

class UserLogReportView extends StatelessWidget {
  final String? usrName;
  const UserLogReportView({super.key, this.usrName});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(usrName),
      tablet: _Tablet(),
    );
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  String fromDate = DateTime.now().toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;
  String? usrName;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    context.read<UserLogBloc>().add(ResetUserLogEvent());
  }

  bool get hasFilter => usrName != null;

  void _clearFilters() {
    setState(() {
      usrName = null;
      fromDate = DateTime.now().toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
    });
    context.read<UserLogBloc>().add(ResetUserLogEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.userLog),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              context.read<UserLogBloc>().add(
                LoadUserLogEvent(
                  usrName: usrName,
                  fromDate: fromDate,
                  toDate: toDate,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 8,

                children: [
                  // User Dropdown
                  Expanded(
                    flex: 3,
                    child: UserDropdown(
                      title: tr.users,
                      isMulti: false,
                      onMultiChanged: (_) {},
                      onSingleChanged: (user) {
                        setState(() {
                          usrName = user?.usrName ?? "";
                        });
                      },
                    ),
                  ),
                  // Date Range
                  Expanded(
                    child: ZDatePicker(
                      label: tr.fromDate,
                      value: fromDate,
                      onDateChanged: (v) {
                        setState(() {
                          fromDate = v;
                          shamsiFromDate = v.toAfghanShamsi;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ZDatePicker(
                      label: tr.toDate,
                      value: toDate,
                      onDateChanged: (v) {
                        setState(() {
                          toDate = v;
                          shamsiToDate = v.toAfghanShamsi;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<UserLogBloc, UserLogState>(
              builder: (context, state) {
                if (state is UserLogInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "USER LOG",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Find user activities here",
                          style: TextStyle(color: color.outline),
                        ),
                      ],
                    ),
                  );
                }
                if (state is UserLogLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UserLogErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                            state.error,
                            style: TextStyle(color: color.error),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is UserLogLoadedState) {
                  if (state.log.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.log.length,
                    itemBuilder: (context, index) {
                      final log = state.log[index];
                      return _buildTabletLogCard(log, color, tr);
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

  Widget _buildTabletLogCard(UserLogModel log, ColorScheme color, AppLocalizations tr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.outline.withValues(alpha: .1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.primary.withValues(alpha: .1),
                  child: Text(
                    log.usrName?.getFirstLetter ?? "U",
                    style: TextStyle(
                      color: color.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            log.usrName ?? "",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.usrRole ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                color: color.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.fullName ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        log.ualTiming?.toDateTime ?? "",
                        style: TextStyle(
                          color: color.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.ualTiming!.toTimeAgo(),
                      style: TextStyle(
                        fontSize: 12,
                        color: color.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details Row
            Row(
              children: [
                // IP and Device
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.outline.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi, size: 16, color: color.outline),
                        const SizedBox(width: 8),
                        Text(
                          log.ualIp ?? "",
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.computer, size: 16, color: color.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.ualDevice ?? "",
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // IDs
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.outline.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${tr.usrId}: ${log.usrId}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${tr.branch}: ${log.usrBranch}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Log Type and Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.secondary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.secondary.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.ualType ?? "",
                      style: TextStyle(
                        color: color.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      log.ualDetails ?? "",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  String fromDate = DateTime.now().toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;
  String? usrName;


  @override
  void initState() {
    super.initState();
    context.read<UserLogBloc>().add(ResetUserLogEvent());
  }


  bool get hasFilter => usrName != null;

  void _clearFilters() {
    setState(() {
      usrName = null;
      fromDate = DateTime.now().toFormattedDate();
      toDate = DateTime.now().toFormattedDate();

    });
    context.read<UserLogBloc>().add(ResetUserLogEvent());
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      estimatedContentHeight: 330,
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 8),
              children: [
                /// 🔹 User Dropdown
                UserDropdown(
                  title: tr.users,
                  isMulti: false,
                  onMultiChanged: (_) {},
                  onSingleChanged: (user) {
                    setSheetState(() {
                      usrName = user?.usrName ?? "";
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// 🔹 Date Range
                Row(
                  children: [
                    Expanded(
                      child: ZDatePicker(
                        label: tr.fromDate,
                        value: fromDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            fromDate = v;
                            shamsiFromDate = v.toAfghanShamsi;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ZDatePicker(
                        label: tr.toDate,
                        value: toDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            toDate = v;
                            shamsiToDate = v.toAfghanShamsi;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// 🔹 Apply / Clear Buttons
                Row(
                  children: [
                    if (hasFilter)
                      Expanded(
                        child: ZOutlineButton(
                          backgroundHover:
                          Theme.of(context).colorScheme.error,
                          isActive: true,
                          onPressed: () {
                            setSheetState(() {
                              usrName = null;
                              fromDate = DateTime.now().toFormattedDate();
                              toDate = DateTime.now().toFormattedDate();
                            });
                            setState(() {});
                          },
                          label: Text(tr.clear),
                        ),
                      ),

                    if (hasFilter) const SizedBox(width: 8),

                    Expanded(
                      child: ZOutlineButton(
                        isActive: true,
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<UserLogBloc>().add(
                            LoadUserLogEvent(
                              usrName: usrName,
                              fromDate: fromDate,
                              toDate: toDate,
                            ),
                          );
                        },
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
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.userLog),
        actions: [
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearFilters,
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
          if (hasFilter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: "${tr.fromDate}: $fromDate",
                      color: color.primary,
                      onRemove: () {
                        setState(() {
                          fromDate = DateTime.now().toFormattedDate();
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: "${tr.toDate}: $toDate",
                      color: color.primary,
                      onRemove: () {
                        setState(() {
                          toDate = DateTime.now().toFormattedDate();
                        });
                      },
                    ),
                    if (usrName != null)
                      _buildFilterChip(
                        label: "${tr.users}: $usrName",
                        color: color.secondary,
                        onRemove: () {
                          setState(() {
                            usrName = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: BlocBuilder<UserLogBloc, UserLogState>(
              builder: (context, state) {
                if (state is UserLogInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "USER LOG",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Find user activities here",
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
                if (state is UserLogLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UserLogErrorState) {
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
                            state.error,
                            style: TextStyle(color: color.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<UserLogBloc>().add(
                                LoadUserLogEvent(usrName: usrName),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(tr.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is UserLogLoadedState) {
                  if (state.log.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.log.length,
                    itemBuilder: (context, index) {
                      final log = state.log[index];
                      return _buildMobileLogCard(log, color, tr);
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

  Widget _buildMobileLogCard(UserLogModel log, ColorScheme color, AppLocalizations tr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.outline.withValues(alpha: .1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.primary.withValues(alpha: .1),
                  child: Text(
                    log.usrName?.getFirstLetter ?? "U",
                    style: TextStyle(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.usrName ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        log.usrRole ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    log.fullName ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      color: color.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // IP and Device
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.outline.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.computer,
                          size: 14,
                          color: color.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            log.ualDevice ?? "",
                            style: TextStyle(
                              fontSize: 12,
                              color: color.outline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        size: 14,
                        color: color.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.ualIp ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Log Type and Details
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.secondary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.secondary.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          log.ualType ?? "",
                          style: TextStyle(
                            fontSize: 11,
                            color: color.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.ualDetails ?? "",
                          style: TextStyle(
                            fontSize: 12,
                            color: color.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Time and IDs
            Row(
              children: [
                // Time
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: color.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.ualTiming?.toDateTime ?? "",
                              style: TextStyle(
                                fontSize: 11,
                                color: color.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              log.ualTiming!.toTimeAgo(),
                              style: TextStyle(
                                fontSize: 10,
                                color: color.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // User ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.outline.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${tr.usrId}:",
                        style: TextStyle(
                          fontSize: 10,
                          color: color.outline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.usrId.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Branch
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.outline.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${tr.branch}:",
                        style: TextStyle(
                          fontSize: 10,
                          color: color.outline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.usrBranch.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  final String? usrName;
  const _Desktop(this.usrName);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  String fromDate = DateTime.now().toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;
  String? usrName;

  @override
  void initState() {
    context.read<UserLogBloc>().add(ResetUserLogEvent());
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.userLog),
        titleSpacing: 0,
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          ZOutlineButton(
            height: 40,
            width: 140,
            icon: Icons.filter_alt_off_outlined,
            isActive: false,
            backgroundHover: Theme.of(context).colorScheme.error,
            label: Text(tr.clearFilters),
            onPressed: () {
              setState(() {
                usrName = null;
                fromDate = DateTime.now().toFormattedDate();
                toDate = DateTime.now().toFormattedDate();
              });
              context.read<UserLogBloc>().add(ResetUserLogEvent());
            },
          ),
          SizedBox(width: 8),
          ZOutlineButton(
            height: 40,
            width: 120,
            icon: Icons.filter_alt,
            isActive: true,
            label: Text(tr.apply),
            onPressed: () {
              context.read<UserLogBloc>().add(
                LoadUserLogEvent(
                  usrName: usrName,
                  fromDate: fromDate,
                  toDate: toDate,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                Expanded(
                  child: UserDropdown(
                    title: tr.users,
                    isMulti: false,
                    onMultiChanged: (_) {},
                    onSingleChanged: (user) {
                      usrName = user?.usrName ?? "";
                    },
                  ),
                ),

                Expanded(
                  child: DateRangeDropdown(
                    onChanged: (fromDate, toDate) {
                      context.read<UserLogBloc>().add(
                        LoadUserLogEvent(
                          usrName: usrName,
                          fromDate: fromDate,
                          toDate: toDate,
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: ZDatePicker(
                    label: tr.fromDate,
                    value: fromDate,
                    onDateChanged: (v) {
                      setState(() {
                        fromDate = v;
                        shamsiFromDate = v.toAfghanShamsi;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: ZDatePicker(
                    label: tr.toDate,
                    value: toDate,
                    onDateChanged: (v) {
                      setState(() {
                        toDate = v;
                        shamsiToDate = v.toAfghanShamsi;
                      });
                    },
                  ),
                ),

              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<UserLogBloc, UserLogState>(
              builder: (context, state) {
                if(state is UserLogInitial){
                  return NoDataWidget(
                    title: "USER LOG",
                    message: "Find user activities here",
                  );
                }
                if (state is UserLogLoadingState) {
                  return Center(child: CircularProgressIndicator());
                }

                if (state is UserLogErrorState) {
                  return NoDataWidget(
                    message: state.error,
                    onRefresh: () {
                      context.read<UserLogBloc>().add(
                        LoadUserLogEvent(usrName: widget.usrName),
                      );
                    },
                  );
                }
                if (state is UserLogLoadedState) {
                  if (state.log.isEmpty) {
                    return NoDataWidget(message: tr.noDataFound,enableAction: false);
                  }
                  return ListView.builder(
                    itemCount: state.log.length,
                    itemBuilder: (context, index) {
                      final log = state.log[index];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.outline.withValues(alpha: .15),
                          ),
                          color: color.surface,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  child: Text(
                                    log.usrName?.getFirstLetter ?? "",
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        spacing: 5,
                                        children: [
                                          Text(
                                            log.usrName ?? "",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),

                                          Text(
                                            log.ualIp ?? "",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: color.outline,
                                                ),
                                          ),

                                          Text(
                                            log.ualDevice ?? "",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                              color: color.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        log.usrRole ?? "",
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  log.fullName?? "",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.outline),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              spacing: 5,
                              children: [
                                Text(
                                  log.ualType ?? "",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(fontSize: 12),
                                ),
                                Text(
                                  log.ualDetails ?? "",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                    color: color.outline.withValues(alpha: .8),
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    spacing: 5,
                                    children: [
                                      Text(
                                        log.ualTiming?.toDateTime ?? "",
                                        style: Theme.of(context).textTheme.bodySmall
                                            ?.copyWith(color: color.primary),
                                      ),
                                      Text(
                                        log.ualTiming!.toTimeAgo(),
                                        style: Theme.of(context).textTheme.bodySmall
                                            ?.copyWith(color: color.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                ZCover(
                                  radius: 3,
                                  padding: EdgeInsets.all(2),
                                  color: color.surface,
                                  child: Row(
                                    spacing: 5,
                                    children: [
                                      Text(
                                        tr.usrId,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        log.usrId.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: color.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 5),
                                ZCover(
                                  radius: 3,
                                  padding: EdgeInsets.all(2),
                                  color: color.surface,
                                  child: Row(
                                    spacing: 5,
                                    children: [
                                      Text(
                                        tr.branch,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        log.usrBranch.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: color.outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
