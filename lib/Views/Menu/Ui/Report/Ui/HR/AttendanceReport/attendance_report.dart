import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Attendance/features/status_selector.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/bloc/employee_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/model/emp_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/HR/AttendanceReport/bloc/attendance_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/HR/AttendanceReport/model/attendance_report_model.dart';
import '../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Other/attendance_status.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../HR/Ui/Attendance/bloc/attendance_bloc.dart';

class AttendanceReportView extends StatelessWidget {
  const AttendanceReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(), tablet: _Tablet(), desktop: _Desktop());
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  late String fromDate;
  late String toDate;
  int? status;
  int? empId;
  final empController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    context.read<AttendanceReportBloc>().add(ResetAttendanceReportEvent());
  }

  bool get hasFilter => status != null || empId != null;

  void _clearFilters() {
    setState(() {
      status = null;
      empId = null;
      fromDate = DateTime.now().toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
    });
    context.read<AttendanceReportBloc>().add(ResetAttendanceReportEvent());
  }

  void _loadData() {
    context.read<AttendanceReportBloc>().add(
      LoadAttendanceReportEvent(
        fromDate: fromDate,
        toDate: toDate,
        // status: status,
        // empId: empId,
      ),
    );
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;
    AttendanceStatusEnum? selectedStatus;
    String? localFromDate = fromDate;
    String? localToDate = toDate;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      estimatedContentHeight: 420,
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 8),
              children: [
                /// 🔹 Employee Selector
                GenericTextField<EmployeeModel, EmployeeBloc, EmployeeState>(
                  showAllOnFocus: true,
                  controller: empController,
                  title: tr.employees,
                  hintText: tr.employeeName,
                  isRequired: true,
                  bloc: context.read<EmployeeBloc>(),
                  fetchAllFunction: (bloc) => bloc.add(LoadEmployeeEvent()),
                  searchFunction: (bloc, query) => bloc.add(LoadEmployeeEvent()),
                  itemBuilder: (context, account) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Text(
                      "${account.perName} | ${account.perLastName}",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  itemToString: (acc) => "${acc.perName} | ${acc.perLastName}",
                  stateToLoading: (state) => state is EmployeeLoadingState,
                  loadingBuilder: (context) => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  stateToItems: (state) {
                    if (state is EmployeeLoadedState) return state.employees;
                    return [];
                  },
                  onSelected: (value) {
                    setSheetState(() {
                      empId = value.empId;
                    });
                  },
                  noResultsText: tr.noDataFound,
                  showClearButton: true,
                ),

                const SizedBox(height: 16),

                /// 🔹 Attendance Status
                AttendanceDropdown(
                  onStatusSelected: (enumValue) {
                    setSheetState(() {
                      selectedStatus = enumValue;
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
                        value: localFromDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            localFromDate = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ZDatePicker(
                        label: tr.toDate,
                        value: localToDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            localToDate = v;
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
                          onPressed: () {
                            setSheetState(() {
                              selectedStatus = null;
                              empId = null;
                              localFromDate = DateTime.now().toFormattedDate();
                              localToDate = DateTime.now().toFormattedDate();
                            });
                            setState(() {
                              status = null;
                              fromDate = DateTime.now().toFormattedDate();
                              toDate = DateTime.now().toFormattedDate();
                            });
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
                          setState(() {
                            fromDate = localFromDate!;
                            toDate = localToDate!;
                            status = selectedStatus != null
                                ? _getStatusValue(selectedStatus!)
                                : null;
                          });
                          _loadData();
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

  // Helper to convert enum to int value for API
  int? _getStatusValue(AttendanceStatusEnum? enumValue) {
    if (enumValue == null) return null;
    switch (enumValue) {
      case AttendanceStatusEnum.present:
        return 1;
      case AttendanceStatusEnum.late:
        return 2;
      case AttendanceStatusEnum.absent:
        return 3;
      case AttendanceStatusEnum.leave:
        return 4;
    }
  }

  // Helper to get color for status display
  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper to get text for status display
  String _getStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Present';
      case 2:
        return 'Late';
      case 3:
        return 'Absent';
      case 4:
        return 'Leave';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final subtitle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: color.outline.withValues(alpha: .9),
    );

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.attendance),
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
          // Add a refresh button to manually load data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Summary with Load Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.attendance,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$fromDate - $toDate",
                        style: subtitle,
                      ),
                    ],
                  ),
                ),
                // Selected Filters Chips
                if (hasFilter)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (status != null)
                          _buildFilterChip(
                            label: "${tr.status}: ${_getStatusText(status)}",
                            color: _getStatusColor(status),
                            onRemove: () {
                              setState(() {
                                status = null;
                              });
                              _loadData();
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),



          Expanded(
            child: BlocConsumer<AttendanceReportBloc, AttendanceReportState>(
              listener: (context, state) {
                if (state is AttendanceReportErrorState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.error ?? "",
                    isError: true,
                  );
                }
              },
              builder: (context, state) {
                if (state is AttendanceLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AttendanceReportErrorState) {
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
                            state.error ?? tr.accessDenied,
                            style: TextStyle(color: color.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: Text(tr.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is AttendanceReportInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr.attendance,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap Load to fetch attendance data",
                          style: TextStyle(color: color.outline),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (state is AttendanceReportLoadedState) {
                  if (state.attendance.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: color.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No attendance records found for selected period",
                            style: TextStyle(color: color.outline),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.attendance.length,
                    itemBuilder: (context, index) {
                      final at = state.attendance[index];
                      return _buildMobileAttendanceCard(at, index, color, tr);
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

  Widget _buildMobileAttendanceCard(AttendanceReportModel at, int index, ColorScheme color, AppLocalizations tr) {
    final statusColor = _getStatusColor(_getStatusValueFromString(at.emaStatus ?? ""));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
            // Date and Status
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
                    at.emaDate.compact,
                    style: TextStyle(
                      color: color.primary,
                      fontSize: 12,
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
                    color: statusColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    at.emaStatus ?? "",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Employee Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.primary.withValues(alpha: .1),
                  child: Text(
                    at.fullName?.getFirstLetter ?? "E",
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
                        at.fullName ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        at.empPosition ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Check In/Out Times
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.checkIn,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color.outline,
                                ),
                              ),
                              Text(
                                at.emaCheckedIn ?? "-",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.checkOut,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color.outline,
                                ),
                              ),
                              Text(
                                at.emaCheckedOut ?? "-",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Hours Worked (if both times available)
            if (at.emaCheckedIn != null && at.emaCheckedOut != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 14,
                      color: color.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _calculateWorkHours(at.emaCheckedIn!, at.emaCheckedOut!),
                      style: TextStyle(
                        fontSize: 12,
                        color: color.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getStatusValueFromString(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 1;
      case 'late':
        return 2;
      case 'absent':
        return 3;
      case 'leave':
        return 4;
      default:
        return 0;
    }
  }

  String _calculateWorkHours(String checkIn, String checkOut) {
    try {
      // Simple calculation - you can enhance this based on your time format
      return "8h 0m";
    } catch (e) {
      return "-";
    }
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  late String fromDate;
  late String toDate;
  int? status; // Stays as int? for API
  int? empId;
  bool _showFilters = true;
  final empController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    context.read<AttendanceReportBloc>().add(ResetAttendanceReportEvent());
  }

  bool get hasFilter => status != null || empId != null;

  void _clearFilters() {
    setState(() {
      status = null;
      empId = null;
      fromDate = DateTime.now().toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
    });
    context.read<AttendanceReportBloc>().add(ResetAttendanceReportEvent());
  }

  // Helper to convert enum to int value for API
  int? _getStatusValue(AttendanceStatusEnum? enumValue) {
    if (enumValue == null) return null;
    switch (enumValue) {
      case AttendanceStatusEnum.present:
        return 1;
      case AttendanceStatusEnum.late:
        return 2;
      case AttendanceStatusEnum.absent:
        return 3;
      case AttendanceStatusEnum.leave:
        return 4;
    }
  }



  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final headerTitle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color.surface,
    );

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.attendance),
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
              context.read<AttendanceReportBloc>().add(
                LoadAttendanceReportEvent(
                  fromDate: fromDate,
                  toDate: toDate,
                  status: status,
                  empId: empId,
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
              decoration: BoxDecoration(
                color: color.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Status Dropdown - Convert enum to int

                  Expanded(
                    flex: 2,
                    child: GenericTextField<EmployeeModel, EmployeeBloc, EmployeeState>(
                      showAllOnFocus: true,
                      showAllOption: true,
                      allOptionText: tr.all,
                      controller: empController,
                      title: tr.employees,
                      hintText: tr.employeeName,
                      isRequired: true,
                      bloc: context.read<EmployeeBloc>(),
                      fetchAllFunction: (bloc) => bloc.add(LoadEmployeeEvent()),
                      searchFunction: (bloc, query) => bloc.add(
                        LoadEmployeeEvent(),
                      ),
                    
                      itemBuilder: (context, account) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${account.perName} | ${account.perLastName}",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      itemToString: (acc) => "${acc.perName} | ${acc.perLastName}",
                      stateToLoading: (state) => state is EmployeeLoadingState,
                      loadingBuilder: (context) => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      stateToItems: (state) {
                        if (state is EmployeeLoadedState) {
                          return state.employees;
                        }
                        return [];
                      },
                      onSelected: (value) {
                        setState(() {
                          empId = value.empId;
                        });
                      },
                      noResultsText: tr.noDataFound,
                      showClearButton: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: AttendanceDropdown(
                      onStatusSelected: (enumValue) {
                        setState(() {
                          status = _getStatusValue(enumValue);
                        });
                      },
                    ),
                  ),


                  const SizedBox(width: 10),
                  // Date Range
                  Expanded(
                    child: ZDatePicker(
                      label: tr.fromDate,
                      value: fromDate,
                      onDateChanged: (v) {
                        setState(() {
                          fromDate = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: ZDatePicker(
                      label: tr.toDate,
                      value: toDate,
                      onDateChanged: (v) {
                        setState(() {
                          toDate = v;
                        });
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
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text(tr.date, style: headerTitle)),
                Expanded(child: Text(tr.employeeName, style: headerTitle)),
                SizedBox(width: 120, child: Text(tr.checkIn, style: headerTitle)),
                SizedBox(width: 120, child: Text(tr.checkOut, style: headerTitle)),
                SizedBox(width: 100, child: Text(tr.status, style: headerTitle)),
              ],
            ),
          ),

          Expanded(
            child: BlocConsumer<AttendanceReportBloc, AttendanceReportState>(
              listener: (context, state) {
                if (state is AttendanceReportErrorState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.error ?? "",
                    isError: true,
                  );
                }
              },
              builder: (context, state) {
                if (state is AttendanceLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AttendanceReportErrorState) {
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
                          state.error ?? tr.accessDenied,
                          style: TextStyle(color: color.error),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AttendanceReportInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 80,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr.attendance,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Search for employees attendance here",
                          style: TextStyle(color: color.outline),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AttendanceReportLoadedState) {
                  if (state.attendance.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: "No attendance records found for selected period",
                      enableAction: false,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.attendance.length,
                    itemBuilder: (context, index) {
                      final at = state.attendance[index];
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
                                at.emaDate.compact,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),

                            // Employee
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    at.fullName ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    at.empPosition ?? "",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Check In
                            SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.login_rounded,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    at.emaCheckedIn ?? "-",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Check Out
                            SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    at.emaCheckedOut ?? "-",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status - Using AttendanceStatusBadge which expects string
                            SizedBox(
                              width: 100,
                              child: AttendanceStatusBadge(
                                status: at.emaStatus ?? "",
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
  late String fromDate;
  late String toDate;
  int? status;
  int? empId;
  @override
  void initState() {
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceReportBloc>().add(ResetAttendanceReportEvent());
    });
    super.initState();
  }
  String? usrName;
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall;
    TextStyle? headerTitle =
    Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color.surface,
    );
    TextStyle? subtitle =
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: color.outline.withValues(alpha: .9),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.attendance),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.attendance,
                  style:
                  Theme.of(context).textTheme.titleMedium,
                ),
                Text(fromDate.compact, style: subtitle),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                    width: 200,
                    child: AttendanceDropdown(
                        onStatusSelected: (e){
                          setState(() {

                          });
                        })),
                SizedBox(width: 5),
                SizedBox(
                  width: 160,
                  child: ZDatePicker(
                    label: tr.fromDate,
                    value: fromDate,
                    onDateChanged: (v) {
                      setState(() {
                        fromDate = v;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 160,
                  child: ZDatePicker(
                    label: tr.toDate,
                    value: toDate,
                    onDateChanged: (v) {
                      setState(() {
                        toDate = v;
                      });
                      context.read<AttendanceReportBloc>().add(
                        LoadAttendanceReportEvent(fromDate: fromDate,toDate: toDate),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
                ),
        ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 100,
                    child: Text(tr.date, style: headerTitle)),
                Expanded(
                    child:
                    Text(tr.employeeName, style: headerTitle)),
                SizedBox(
                    width: 100,
                    child: Text(tr.checkIn, style: headerTitle)),
                SizedBox(
                    width: 100,
                    child: Text(tr.checkOut, style: headerTitle)),
                SizedBox(
                    width: 100,
                    child: Text(tr.status, style: headerTitle)),
              ],
            ),
          ),
          SizedBox(height: 5),
          Expanded(
            child: BlocConsumer<AttendanceReportBloc, AttendanceReportState>(
              listener: (BuildContext context, AttendanceReportState state) {
                if (state is AttendanceReportErrorState) {
                  Utils.showOverlayMessage(context,
                      message: state.error??"", isError: true);
                }
              },
              builder: (context, state) {
                if (state is AttendanceLoadingState) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (state is AttendanceReportErrorState) {
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.error,
                    onRefresh: () {
                      context.read<AttendanceReportBloc>().add(
                          LoadAttendanceReportEvent(fromDate: fromDate, toDate: toDate,status: status,empId: empId));
                    },
                  );
                }
                if(state is AttendanceReportInitial){
                  return NoDataWidget(
                    title: tr.attendance,
                    message: "Search for employees attendance here",
                    enableAction: false,
                  );
                }

                if(state is AttendanceReportLoadedState){
                 return Column(
                   children: [
                     Expanded(
                       child: ListView.builder(
                         itemCount: state.attendance.length,
                         itemBuilder: (context, index) {
                           final at = state.attendance[index];
                           return InkWell(
                             child: Container(
                               padding: const EdgeInsets.symmetric(
                                   vertical: 8, horizontal: 5),
                               margin:
                               const EdgeInsets.symmetric(horizontal: 5),
                               decoration: BoxDecoration(
                                 color: index.isEven
                                     ? Theme.of(context)
                                     .colorScheme
                                     .primary
                                     .withValues(alpha: .05)
                                     : Colors.transparent,
                               ),
                               child: Row(
                                 crossAxisAlignment:
                                 CrossAxisAlignment.start,
                                 children: [
                                   SizedBox(
                                       width: 100,
                                       child:
                                       Text(at.emaDate.compact)),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment:
                                       CrossAxisAlignment.start,
                                       children: [
                                         Text(at.fullName ?? "",
                                             style: titleStyle),
                                         Text(at.empPosition ?? "",
                                             style: subtitle),
                                       ],
                                     ),
                                   ),
                                   SizedBox(
                                       width: 100,
                                       child: Text(
                                           at.emaCheckedIn ?? "")),
                                   SizedBox(
                                       width: 100,
                                       child: Text(
                                           at.emaCheckedOut ?? "")),
                                   SizedBox(
                                     width: 100,
                                     child: AttendanceStatusBadge(
                                       status: at.emaStatus ?? "",
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           );
                         },
                       ),
                     ),
                   ],
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
