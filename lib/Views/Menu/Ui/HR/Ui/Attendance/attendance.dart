import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Attendance/bloc/attendance_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Attendance/time_selector.dart';
import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Other/attendance_status.dart';
import '../../../../../../Features/Other/toast.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';
import 'edit_attendance.dart';
import 'features/status_selector.dart';
import 'model/attendance_model.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(),
      tablet: _Desktop(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  late String selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now().toFormattedDate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceBloc>().add(LoadAllAttendanceEvent(date: selectedDate));
    });
  }

  Future<void> _onRefresh() async {
    context.read<AttendanceBloc>().add(LoadAllAttendanceEvent(date: selectedDate));
    // Optional: Wait for the loading to complete
    await context.read<AttendanceBloc>().stream.firstWhere(
          (state) => state is! AttendanceLoadingState && state is! AttendanceSilentLoadingState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = state.loginData;
    final usrName = state.loginData.usrName;

    return Scaffold(
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceErrorState) {
            ToastManager.show(context: context, message: state.message, type: ToastType.error);
          }
          if (state is AttendanceErrorState) {
            ToastManager.show(context: context, message: state.message, type: ToastType.error);
          }
        },
        builder: (context, state) {
          // Loading state
          if (state is AttendanceLoadingState && state is! AttendanceLoadedState) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (state is AttendanceErrorState) {
            return Center(
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
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: Text(tr.retry),
                  ),
                ],
              ),
            );
          }

          // Get attendance data
          final attendance = state is AttendanceLoadedState
              ? state.attendance
              : state is AttendanceSilentLoadingState
              ? state.attendance
              : <AttendanceRecord>[];

          return Column(
            children: [
              // Date Selector and Summary
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Date Picker Row
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          flex: 4,
                          child: ZDatePicker(
                            label: "",
                            value: selectedDate,
                            onDateChanged: (v) {
                              setState(() => selectedDate = v);
                              context.read<AttendanceBloc>().add(
                                LoadAllAttendanceEvent(date: selectedDate),
                              );
                            },
                          ),
                        ),
                        if (login.hasPermission(106) ?? false)
                          Expanded(
                            flex: 2,
                            child: ZOutlineButton(
                              height: 40,
                              isActive: true,
                              label: Text(tr.newKeyword),
                              onPressed: () => _showAddAttendanceBottomSheet(context, tr, usrName),
                            ),
                          ),
                      ],
                    ),

                    // Summary Cards
                    if (attendance.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildMobileSummaryCard(
                              context,
                              label: tr.presentTitle,
                              count: attendance.present,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildMobileSummaryCard(
                              context,
                              label: tr.lateTitle,
                              count: attendance.late,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            _buildMobileSummaryCard(
                              context,
                              label: tr.absentTitle,
                              count: attendance.absent,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            _buildMobileSummaryCard(
                              context,
                              label: tr.leaveTitle,
                              count: attendance.leave,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildMobileSummaryCard(
                              context,
                              label: tr.totalTitle,
                              count: attendance.length,
                              color: color.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Attendance List
              Expanded(
                child: attendance.isEmpty
                    ? NoDataWidget(
                  title: tr.noDataFound,
                  message: "${tr.noAttendance} - ${selectedDate.compact}",
                  enableAction: false,
                )
                    : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: attendance.length,
                    itemBuilder: (context, index) {
                      final at = attendance[index];
                      return _buildMobileAttendanceCard(
                        context,
                        record: at,
                        onTap: (login.hasPermission(108) ?? false)
                            ? () => _showEditAttendanceBottomSheet(context, at, tr, usrName)
                            : null,
                      );
                    },
                  ),
                ),
              ),

              // Silent loading indicator
              if (state is AttendanceSilentLoadingState)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.black.withValues(alpha: .05),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color.primary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileSummaryCard(
      BuildContext context, {
        required String label,
        required int count,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAttendanceCard(
      BuildContext context, {
        required AttendanceRecord record,
        required VoidCallback? onTap,
      }) {
    final color = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(record.emaStatus ?? "");

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.outline.withValues(alpha: .1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Name and Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.fullName ?? "-",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          record.empPosition ?? "-",
                          style: TextStyle(
                            fontSize: 12,
                            color: color.onSurface.withValues(alpha: .6),
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
                      color: statusColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      record.emaStatus ?? "-",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date and Time Row
              Row(
                children: [
                  // Date
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: color.primary.withValues(alpha: .7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.emaDate.compact,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.onSurface.withValues(alpha: .8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Check In
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 14,
                          color: Colors.green.withValues(alpha: .7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.emaCheckedIn ?? "-",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Check Out
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 14,
                          color: Colors.red.withValues(alpha: .7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.emaCheckedOut ?? "-",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Hours Worked (optional)
              if (record.emaCheckedIn != null && record.emaCheckedOut != null) ...[
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
                        size: 12,
                        color: color.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _calculateWorkHours(record.emaCheckedIn!, record.emaCheckedOut!),
                        style: TextStyle(
                          fontSize: 11,
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
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _calculateWorkHours(String checkIn, String checkOut) {
    try {
      // Simple calculation - you might want to implement proper time difference
      return "8h 0m";
    } catch (e) {
      return "-";
    }
  }

  void _showAddAttendanceBottomSheet(BuildContext context, AppLocalizations tr, String? usrName) {
    String? checkIn;
    String? checkOut;
    String localDate = selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      tr.addAttendance,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Date Picker
                      ZDatePicker(
                        label: tr.date,
                        value: localDate,
                        onDateChanged: (v) => localDate = v,
                      ),

                      const SizedBox(height: 16),

                      // Check In Time
                      TimePickerField(
                        label: tr.checkIn,
                        initialTime: '08:00:00',
                        onChanged: (time) => checkIn = time,
                      ),

                      const SizedBox(height: 16),

                      // Check Out Time
                      TimePickerField(
                        label: tr.checkOut,
                        initialTime: '16:00:00',
                        onChanged: (time) => checkOut = time,
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ZOutlineButton(
                        onPressed: () => Navigator.pop(context),
                        label: Text(tr.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<AttendanceBloc, AttendanceState>(
                        builder: (context, state) {
                          final isLoading = state is AttendanceSilentLoadingState;

                          return ZOutlineButton(
                            onPressed: isLoading
                                ? null
                                : () {
                              context.read<AttendanceBloc>().add(
                                AddAttendanceEvent(
                                  usrName: usrName ?? "",
                                  checkIn: checkIn ?? "08:00:00",
                                  checkOut: checkOut ?? "16:00:00",
                                  date: localDate,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            label: isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(tr.submit),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditAttendanceBottomSheet(BuildContext context, AttendanceRecord record, AppLocalizations tr, String? usrName,) {
    String? checkIn = record.emaCheckedIn;
    String? checkOut = record.emaCheckedOut;
    String? localDate = record.emaDate;
    AttendanceStatusEnum? selectedStatus = AttendanceStatusEnum.fromDatabaseValue(record.emaStatus ?? "Present");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      children: [
                        Text(
                          "${tr.edit} - ${record.fullName}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Employee Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.fullName ?? "-",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                record.empPosition ?? "-",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(record.emaStatus ?? "").withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            record.emaStatus ?? "-",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(record.emaStatus ?? ""),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [

                          // Check In Time
                          TimePickerField(
                            label: tr.checkIn,
                            initialTime: checkIn ?? '08:00:00',
                            onChanged: (time) => checkIn = time,
                          ),

                          const SizedBox(height: 10),

                          // Check Out Time
                          TimePickerField(
                            label: tr.checkOut,
                            initialTime: checkOut ?? '16:00:00',
                            onChanged: (time) => checkOut = time,
                          ),

                          const SizedBox(height: 10),

                          // Status Dropdown - Using AttendanceDropdown
                          AttendanceDropdown(
                            selectedStatus: selectedStatus,
                            onStatusSelected: (status) {
                              setState(() {
                                selectedStatus = status;
                              });
                            },
                          ),

                          const SizedBox(height: 10),

                          // Current Values Info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.currentValues,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${tr.checkIn}: ${record.emaCheckedIn ?? '--:--:--'}"),
                                    Text("${tr.checkOut}: ${record.emaCheckedOut ?? '--:--:--'}"),
                                  ],
                                ),
                                Text("${tr.status}: ${record.emaStatus ?? '--'}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ZOutlineButton(
                            onPressed: () => Navigator.pop(context),
                            label: Text(tr.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BlocBuilder<AttendanceBloc, AttendanceState>(
                            builder: (context, state) {
                              final isLoading = state is AttendanceSilentLoadingState;

                              return ZOutlineButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  // Create updated record
                                  final updatedRecord = AttendanceRecord(
                                    usrName: record.usrName,
                                    emaId: record.emaId,
                                    emaEmployee: record.emaEmployee,
                                    fullName: record.fullName,
                                    emaCheckedIn: checkIn,
                                    emaCheckedOut: checkOut,
                                    emaStatus: selectedStatus?.toDatabaseValue(),
                                    emaDate: localDate,
                                    empPosition: record.empPosition,
                                  );

                                  // Create AttendanceModel with updated record
                                  final attendanceModel = AttendanceModel(
                                    usrName: usrName,
                                    records: [updatedRecord],
                                  );

                                  // Dispatch update event
                                  context.read<AttendanceBloc>().add(
                                    UpdateAttendanceEvent(attendanceModel),
                                  );
                                  Navigator.pop(context);
                                },
                                isActive: true,
                                label: isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : Text(tr.update),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  late String date;

  @override
  void initState() {
    date = DateTime.now().toFormattedDate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceBloc>().add(LoadAllAttendanceEvent());
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

    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = state.loginData;
    usrName = state.loginData.usrName;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, attState) {
                final attendance = attState is AttendanceLoadedState
                    ? attState.attendance
                    : attState is AttendanceSilentLoadingState
                    ? attState.attendance
                    : <AttendanceRecord>[];

                return Row(
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
                        Text(date.compact, style: subtitle),
                      ],
                    ),
                    Row(
                      children: [
                        if (attendance.isNotEmpty)
                          AttendanceSummary(attendance: attendance),
                        const SizedBox(width: 3),
                        SizedBox(
                          width: 160,
                          child: ZDatePicker(
                            label: "",
                            value: date,
                            onDateChanged: (v) {
                              setState(() {
                                date = v;
                              });
                              context.read<AttendanceBloc>().add(
                                LoadAllAttendanceEvent(date: date),
                              );
                            },
                          ),
                        ),
                        if(login.hasPermission(106) ?? false)...[
                          const SizedBox(width: 8),
                          ZOutlineButton(
                            height: 46,
                            isActive: true,
                            onPressed: () => addAttendance(tr),
                            icon: Icons.add,
                            label: Text(tr.addAttendance),
                          )
                        ],

                      ],
                    ),
                  ],
                );
              },
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
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                if (state is AttendanceLoadingState) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (state is AttendanceErrorState) {
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.message,
                    onRefresh: () {
                      context.read<AttendanceBloc>().add(
                          LoadAllAttendanceEvent());
                    },
                  );
                }

                final attendance = state is AttendanceLoadedState
                    ? state.attendance
                    : state is AttendanceSilentLoadingState
                    ? state.attendance
                    : <AttendanceRecord>[];

                if (attendance.isEmpty) {
                  return NoDataWidget(
                    title: tr.noDataFound,
                    message: "${tr.noAttendance} - ${date.compact}",
                    enableAction: false,
                  );
                }
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: attendance.length,
                            itemBuilder: (context, index) {
                              final at = attendance[index];
                              return InkWell(
                                onTap: login.hasPermission(108) ?? false ? () => _editAttendance(at, tr) : null,
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
                    ),

                    if (state is AttendanceSilentLoadingState)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .3),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface,
                            ),
                          ),
                        ),
                      ),
                  ],
                );

              },
            ),
          ),
        ],
      ),
    );
  }

  void addAttendance(AppLocalizations tr) {
    String? checkIn;
    String? checkOut;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocListener<AttendanceBloc, AttendanceState>(
          listenWhen: (prev, curr) =>
          curr is AttendanceSuccessState || curr is AttendanceErrorState,
          listener: (context, state) {
            /// ✅ CLOSE dialog on success
            if (state is AttendanceLoadedState) {
              Navigator.pop(dialogContext);
            }

            if (state is AttendanceSuccessState) {
              Navigator.pop(dialogContext);
              ToastManager.show(
                context: context,
                title: tr.successTitle,
                message: state.message,
                type: ToastType.success,
                durationInSeconds: 4,
              );
            }

            /// ❌ Keep dialog open on error
            if (state is AttendanceErrorState) {
              ToastManager.show(
                context: context,
                title: tr.operationFailedTitle,
                message: state.message,
                type: ToastType.error,
                durationInSeconds: 4,
              );
            }
          },
          child: ZFormDialog(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            icon: Icons.access_time,
            title: tr.addAttendance,
            width: 500,
            onAction: () {
              context.read<AttendanceBloc>().add(
                AddAttendanceEvent(
                  usrName: usrName ?? "",
                  checkIn: checkIn ?? "08:00:00",
                  checkOut: checkOut ?? "16:00:00",
                  date: date,
                ),
              );
            },

            actionLabel: BlocBuilder<AttendanceBloc, AttendanceState>(
              buildWhen: (prev, curr) =>
              curr is AttendanceSilentLoadingState ||
                  curr is AttendanceLoadedState ||
                  curr is AttendanceErrorState,
              builder: (context, state) {
                final isLoading = state is AttendanceSilentLoadingState;

                if (isLoading) {
                  return const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                return Text(tr.submit);
              },
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ZDatePicker(
                    label: tr.date,
                    value: date,
                    onDateChanged: (v) {
                      setState(() => date = v);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TimePickerField(
                  label: tr.checkIn,
                  initialTime: '08:00:00',
                  onChanged: (time) => checkIn = time,
                ),
                const SizedBox(height: 12),
                TimePickerField(
                  label: tr.checkOut,
                  initialTime: '16:00:00',
                  onChanged: (time) => checkOut = time,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editAttendance(AttendanceRecord record, AppLocalizations tr) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAttendanceDialog(
          record: record,
          currentDate: date,
        );
      },
    );
  }

}


class AttendanceSummary extends StatelessWidget {
  final List<AttendanceRecord> attendance;

  const AttendanceSummary({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildCard(context, tr.presentTitle, attendance.present, Colors.green),
          _buildCard(context, tr.lateTitle, attendance.late, Colors.orange),
          _buildCard(context, tr.absentTitle, attendance.absent, Colors.red),
          _buildCard(context, tr.leaveTitle, attendance.leave, Colors.blue),
          _buildCard(
            context,
            tr.totalTitle,
            attendance.length,
            Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      String title,
      int value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
