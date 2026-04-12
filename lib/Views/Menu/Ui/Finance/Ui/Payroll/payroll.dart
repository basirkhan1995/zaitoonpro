import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/alert_dialog.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Payroll/bloc/payroll_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Payroll/model/payroll_model.dart';
import '../../../../../../Features/Date/month_year_picker.dart';
import '../../../../../../Features/Generic/shimmer.dart';
import '../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';

class PayrollView extends StatelessWidget {
  const PayrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  final Set<int> _selectedIds = {};
  final Map<int, bool> _localPaymentStatus = {}; // Track local changes
  bool _selectAll = false;

  void _toggleRecordSelection(int perId, bool currentPaidStatus) {
    setState(() {
      if (_selectedIds.contains(perId)) {
        _selectedIds.remove(perId);
        // When unselected, revert to original payment status
        _localPaymentStatus.remove(perId);
      } else {
        _selectedIds.add(perId);
        // When selected, toggle payment status
        _localPaymentStatus[perId] = !currentPaidStatus;
      }
    });
  }

  void _toggleSelectAll(List<PayrollModel> payroll) {
    setState(() {
      if (_selectAll) {
        _selectedIds.clear();
        _localPaymentStatus.clear();
      } else {
        // Select ALL records (both paid and unpaid)
        for (final record in payroll) {
          _selectedIds.add(record.perId!);
          // For select all, we'll mark unpaid as selected for payment
          // and keep paid as is (they'll remain checked)
          if ((record.payment ?? 0) == 0) {
            _localPaymentStatus[record.perId!] = true; // Mark unpaid for payment
          } else {
            _localPaymentStatus[record.perId!] = true; // Keep paid checked
          }
        }
      }
      _selectAll = !_selectAll;
    });
  }

  void _postSelectedPayroll(BuildContext context, String usrName, List<PayrollModel> payroll) {
    // Update payment status based on local changes
    final updatedRecords = payroll.map((record) {
      final perId = record.perId!;

      if (_selectedIds.contains(perId)) {
        // This record was selected for change
        final newPaymentStatus = _localPaymentStatus[perId] ?? true;
        return record.copyWith(payment: newPaymentStatus ? 1 : 0);
      } else {
        // Not selected - keep original payment status
        return record;
      }
    }).toList();

    final selectedCount = _selectedIds.length;
    final toBePaidCount = updatedRecords
        .where((r) => _selectedIds.contains(r.perId) && (r.payment ?? 0) == 1)
        .length;
    final toBeUnpaidCount = selectedCount - toBePaidCount;

    if (selectedCount == 0) {
      ToastManager.show(
        context: context,
        message: "Please select records to update",
        type: ToastType.error,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return ZAlertDialog(
          title: AppLocalizations.of(context)!.areYouSure,
          content: '',
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (toBePaidCount > 0)
                  Text("Mark $toBePaidCount employees as PAID"),
                if (toBeUnpaidCount > 0)
                  Text("Mark $toBeUnpaidCount employees as UNPAID",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      )),
                Text("All payroll records will be updated!",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )),
              ],
            ),
          ),
          onYes: () {
            context.read<PayrollBloc>().add(
              PostPayrollEvent(usrName, updatedRecords),
            );
            setState(() {
              _selectedIds.clear();
              _localPaymentStatus.clear();
              _selectAll = false;
            });
          },
        );
      },
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _localPaymentStatus.clear();
      _selectAll = false;
    });
  }

  // Helper to get visual checkbox state
  bool _getCheckboxValue(PayrollModel record) {
    final perId = record.perId!;
    final isPaid = (record.payment ?? 0) == 1;

    if (_selectedIds.contains(perId)) {
      // If selected, use local payment status
      return _localPaymentStatus[perId] ?? isPaid;
    } else {
      // If not selected, use original payment status
      return isPaid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }

    final usrName = authState.loginData.usrName;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.payRoll, style: textTheme.titleLarge),
                    BlocBuilder<PayrollBloc, PayrollState>(
                      builder: (context, state) {
                        final payroll = state.payroll;
                        final unpaidCount = payroll
                            .where((r) => (r.payment ?? 0) == 0)
                            .length;
                        final paidCount = payroll
                            .where((r) => (r.payment ?? 0) == 1)
                            .length;
                        return Text(
                          '${_selectedIds.length} ${tr.selected} | $unpaidCount ${tr.unpaidTitle} | $paidCount ${tr.paidTitle}',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.outline.withValues(alpha: .9),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Clear Selection
                    if (_selectedIds.isNotEmpty)
                      ZOutlineButton(
                        height: 45,
                        backgroundHover: Theme.of(context).colorScheme.error,
                        icon: Icons.clear,
                        onPressed: _clearSelection,
                        label: Text(tr.clear),
                      ),
                    const SizedBox(width: 5),
                    // Select All
                    BlocBuilder<PayrollBloc, PayrollState>(
                      builder: (context, state) {
                        final payroll = state.payroll;
                        final allSelected = payroll.isNotEmpty &&
                            _selectedIds.length == payroll.length;

                        return ZOutlineButton(
                          height: 45,
                          icon: allSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          onPressed: payroll.isNotEmpty
                              ? () => _toggleSelectAll(payroll)
                              : null,
                          label: Text(
                            allSelected ? tr.disselect : tr.selectAll,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 5),

                    // Payment Button
                    if (_selectedIds.isNotEmpty)
                      BlocBuilder<PayrollBloc, PayrollState>(
                        builder: (context, state) {
                          return ZOutlineButton(
                            height: 45,
                            icon: Icons.payment_rounded,
                            onPressed: _selectedIds.isNotEmpty
                                ? () => _postSelectedPayroll(
                              context,
                              usrName!,
                              state.payroll,
                            ) : null,
                            label: Text(tr.postSalary),
                          );
                        },
                      ),

                    const SizedBox(width: 5),

                    // Refresh Button
                    ZOutlineButton(
                      height: 45,
                      isActive: true,
                      icon: Icons.refresh,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => MonthYearPicker(
                            onMonthYearSelected: (date) {
                              context.read<PayrollBloc>().add(
                                LoadPayrollEvent(date),
                              );
                              _clearSelection();
                            },
                            initialDate: DateTime.now(),
                            minYear: 2020,
                            maxYear: 2200,
                            disablePastDates: false,
                          ),
                        );
                      },
                      label: Text(tr.loadPayroll),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '#',
                      style: textTheme.titleSmall?.copyWith(color: color.surface),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr.employees,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    tr.salaryBase,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),

                SizedBox(
                  width: 120,
                  child: Text(
                    tr.salaryAmount,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    tr.overtime,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    tr.totalPayable,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 105,
                  child: Text(
                    tr.status,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Payroll List
          Expanded(
            child: BlocConsumer<PayrollBloc, PayrollState>(
              listener: (context, state) {
                if (state is PayrollSuccessState) {
                  ToastManager.show(
                    context: context,
                    title: tr.successTitle,
                    message: state.message,
                    type: ToastType.success,
                  );
                }
                if (state is PayrollErrorState && state.message.isNotEmpty) {
                  ToastManager.show(
                    context: context,
                    title: tr.operationFailedTitle,
                    message: state.message,
                    type: ToastType.error,
                  );
                }
              },
              builder: (context, state) {
                final payroll = state.payroll;

                if (payroll.isEmpty && state is! PayrollLoadingState) {
                  return NoDataWidget(
                    title: tr.noData,
                    message: tr.noDataFound,
                    enableAction: false,
                  );
                }

                if (state is PayrollLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    ListView.builder(
                      itemCount: payroll.length,
                      itemBuilder: (context, index) {
                        final record = payroll[index];
                        final isPaid = (record.payment ?? 0) == 1;
                        final isSelected = _selectedIds.contains(record.perId);
                        final checkboxValue = _getCheckboxValue(record);
                        final visualIsPaid = isSelected ? _localPaymentStatus[record.perId!] ?? isPaid : isPaid;

                        return InkWell(
                          hoverColor: color.surface,
                          splashColor: color.surface,
                          highlightColor: color.surface,
                          onTap: () => _toggleRecordSelection(record.perId!, isPaid),
                          onLongPress: () => _toggleRecordSelection(record.perId!, isPaid),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            margin: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.primary.withValues(alpha: .03)
                                  : index.isEven
                                  ? color.primary.withValues(alpha: .03)
                                  : Colors.transparent,
                              border: isSelected
                                  ? Border.all(
                                color: color.primary.withValues(
                                  alpha: .2,
                                ),
                                width: 1,
                              )
                                  : null,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              children: [
                                // Checkbox - FIXED: Shows immediate visual feedback
                                SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Checkbox(
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      value: checkboxValue, // Use the computed value
                                      onChanged: (value) {
                                        _toggleRecordSelection(record.perId!, isPaid);
                                      },
                                      // Visual styling
                                      fillColor: visualIsPaid
                                          ? WidgetStateProperty.all(Colors.green.withValues(alpha: .7))
                                          : null,
                                      checkColor: visualIsPaid ? Colors.white : null,
                                    ),
                                  ),
                                ),

                                // Employee
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(record.fullName ?? ''),
                                      Text(
                                        '${record.salaryAccount}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Salary Base
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.salary.toAmount(),
                                        style: textTheme.titleSmall,
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Salary Payable
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.salaryPayable.toAmount(),
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Overtime
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.overtimePayable.toAmount(),
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Total Payable
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.totalPayable.toAmount(),
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status - Show visual status based on local changes
                                SizedBox(
                                  width: 105,
                                  child: StatusBadge(
                                    status: visualIsPaid ? 1 : 0,
                                    trueValue: tr.paidTitle,
                                    falseValue: tr.unpaidTitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    if (state is PayrollSilentLoadingState)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.surface,
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
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => __DesktopState();
}

class __DesktopState extends State<_Desktop> {
  final Set<int> _selectedIds = {};
  final Map<int, bool> _localPaymentStatus = {}; // Track local changes
  bool _selectAll = false;

  void _toggleRecordSelection(int perId, bool currentPaidStatus) {
    setState(() {
      if (_selectedIds.contains(perId)) {
        _selectedIds.remove(perId);
        // When unselected, revert to original payment status
        _localPaymentStatus.remove(perId);
      } else {
        _selectedIds.add(perId);
        // When selected, toggle payment status
        _localPaymentStatus[perId] = !currentPaidStatus;
      }
    });
  }

  void _toggleSelectAll(List<PayrollModel> payroll) {
    setState(() {
      if (_selectAll) {
        _selectedIds.clear();
        _localPaymentStatus.clear();
      } else {
        // Select ALL records (both paid and unpaid)
        for (final record in payroll) {
          _selectedIds.add(record.perId!);
          // For select all, we'll mark unpaid as selected for payment
          // and keep paid as is (they'll remain checked)
          if ((record.payment ?? 0) == 0) {
            _localPaymentStatus[record.perId!] = true; // Mark unpaid for payment
          } else {
            _localPaymentStatus[record.perId!] = true; // Keep paid checked
          }
        }
      }
      _selectAll = !_selectAll;
    });
  }

  void _postSelectedPayroll(BuildContext context, String usrName, List<PayrollModel> payroll) {
    // Update payment status based on local changes
    final updatedRecords = payroll.map((record) {
      final perId = record.perId!;

      if (_selectedIds.contains(perId)) {
        // This record was selected for change
        final newPaymentStatus = _localPaymentStatus[perId] ?? true;
        return record.copyWith(payment: newPaymentStatus ? 1 : 0);
      } else {
        // Not selected - keep original payment status
        return record;
      }
    }).toList();

    final selectedCount = _selectedIds.length;
    final toBePaidCount = updatedRecords
        .where((r) => _selectedIds.contains(r.perId) && (r.payment ?? 0) == 1)
        .length;
    final toBeUnpaidCount = selectedCount - toBePaidCount;

    if (selectedCount == 0) {
      ToastManager.show(
        context: context,
        message: "Please select records to update",
        type: ToastType.error,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return ZAlertDialog(
          title: AppLocalizations.of(context)!.areYouSure,
          content: '',
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (toBePaidCount > 0)
                  Text("Mark $toBePaidCount employees as PAID"),
                if (toBeUnpaidCount > 0)
                  Text("Mark $toBeUnpaidCount employees as UNPAID",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      )),
                Text("All payroll records will be updated!",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )),
              ],
            ),
          ),
          onYes: () {
            context.read<PayrollBloc>().add(
              PostPayrollEvent(usrName, updatedRecords),
            );
            setState(() {
              _selectedIds.clear();
              _localPaymentStatus.clear();
              _selectAll = false;
            });
          },
        );
      },
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _localPaymentStatus.clear();
      _selectAll = false;
    });
  }

  // Helper to get visual checkbox state
  bool _getCheckboxValue(PayrollModel record) {
    final perId = record.perId!;
    final isPaid = (record.payment ?? 0) == 1;

    if (_selectedIds.contains(perId)) {
      // If selected, use local payment status
      return _localPaymentStatus[perId] ?? isPaid;
    } else {
      // If not selected, use original payment status
      return isPaid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }

    final usrName = authState.loginData.usrName;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.payRoll, style: textTheme.titleLarge),
                    BlocBuilder<PayrollBloc, PayrollState>(
                      builder: (context, state) {
                        final payroll = state.payroll;
                        final unpaidCount = payroll
                            .where((r) => (r.payment ?? 0) == 0)
                            .length;
                        final paidCount = payroll
                            .where((r) => (r.payment ?? 0) == 1)
                            .length;
                        return Text(
                          '${_selectedIds.length} ${tr.selected} | $unpaidCount ${tr.unpaidTitle} | $paidCount ${tr.paidTitle}',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.outline.withValues(alpha: .9),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Clear Selection
                    if (_selectedIds.isNotEmpty)
                      ZOutlineButton(
                        height: 45,
                        backgroundHover: Theme.of(context).colorScheme.error,
                        icon: Icons.clear,
                        onPressed: _clearSelection,
                        label: Text(tr.clear),
                      ),
                    const SizedBox(width: 5),
                    // Select All
                    BlocBuilder<PayrollBloc, PayrollState>(
                      builder: (context, state) {
                        final payroll = state.payroll;
                        final allSelected = payroll.isNotEmpty &&
                            _selectedIds.length == payroll.length;

                        return ZOutlineButton(
                          height: 45,
                          icon: allSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          onPressed: payroll.isNotEmpty
                              ? () => _toggleSelectAll(payroll)
                              : null,
                          label: Text(
                            allSelected ? tr.disselect : tr.selectAll,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 5),

                    // Payment Button
                    if (_selectedIds.isNotEmpty)
                      BlocBuilder<PayrollBloc, PayrollState>(
                        builder: (context, state) {
                          return ZOutlineButton(
                            height: 45,
                            icon: Icons.payment_rounded,
                            onPressed: _selectedIds.isNotEmpty
                                ? () => _postSelectedPayroll(
                              context,
                              usrName!,
                              state.payroll,
                            ) : null,
                            label: Text(tr.postSalary),
                          );
                        },
                      ),

                    const SizedBox(width: 5),

                    // Refresh Button
                    ZOutlineButton(
                      height: 45,
                      isActive: true,
                      icon: Icons.refresh,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => MonthYearPicker(
                            onMonthYearSelected: (date) {
                              context.read<PayrollBloc>().add(
                                LoadPayrollEvent(date),
                              );
                              _clearSelection();
                            },
                            initialDate: DateTime.now(),
                            minYear: 2020,
                            maxYear: 2200,
                            disablePastDates: false,
                          ),
                        );
                      },
                      label: Text(tr.loadPayroll),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '#',
                      style: textTheme.titleSmall?.copyWith(color: color.surface),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    tr.date,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr.employees,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    tr.salaryBase,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    tr.baseHours,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    tr.workedDays,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    tr.salaryAmount,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    tr.overtime,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    tr.totalPayable,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
                SizedBox(
                  width: 105,
                  child: Text(
                    tr.status,
                    style: textTheme.titleSmall?.copyWith(color: color.surface),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Payroll List
          Expanded(
            child: BlocConsumer<PayrollBloc, PayrollState>(
              listener: (context, state) {
                if (state is PayrollSuccessState) {
                  ToastManager.show(
                    context: context,
                    title: tr.successTitle,
                    message: state.message,
                    type: ToastType.success,
                  );
                }
                if (state is PayrollErrorState && state.message.isNotEmpty) {
                  ToastManager.show(
                    context: context,
                    title: tr.operationFailedTitle,
                    message: state.message,
                    type: ToastType.error,
                  );
                }
              },
              builder: (context, state) {
                final payroll = state.payroll;

                if (payroll.isEmpty && state is! PayrollLoadingState) {
                  return NoDataWidget(
                    title: tr.noData,
                    message: tr.noDataFound,
                    enableAction: false,
                  );
                }

                if (state is PayrollLoadingState) {
                  return UniversalShimmer.dataList(
                    itemCount: 15,
                    numberOfColumns: 6,
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      itemCount: payroll.length,
                      itemBuilder: (context, index) {
                        final record = payroll[index];
                        final isPaid = (record.payment ?? 0) == 1;
                        final isSelected = _selectedIds.contains(record.perId);
                        final checkboxValue = _getCheckboxValue(record);
                        final visualIsPaid = isSelected ? _localPaymentStatus[record.perId!] ?? isPaid : isPaid;

                        return InkWell(
                          hoverColor: color.surface,
                          splashColor: color.surface,
                          highlightColor: color.surface,
                          onTap: () => _toggleRecordSelection(record.perId!, isPaid),
                          onLongPress: () => _toggleRecordSelection(record.perId!, isPaid),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            margin: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.primary.withValues(alpha: .03)
                                  : index.isEven
                                  ? color.primary.withValues(alpha: .03)
                                  : Colors.transparent,
                              border: isSelected
                                  ? Border.all(
                                color: color.primary.withValues(
                                  alpha: .2,
                                ),
                                width: 1,
                              )
                                  : null,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              children: [
                                // Checkbox - FIXED: Shows immediate visual feedback
                                SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Checkbox(
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      value: checkboxValue, // Use the computed value
                                      onChanged: (value) {
                                        _toggleRecordSelection(record.perId!, isPaid);
                                      },
                                      // Visual styling
                                      fillColor: visualIsPaid
                                          ? WidgetStateProperty.all(Colors.green.withValues(alpha: .7))
                                          : null,
                                      checkColor: visualIsPaid ? Colors.white : null,
                                    ),
                                  ),
                                ),

                                // Date
                                SizedBox(
                                  width: 100,
                                  child: Text(record.monthYear ?? ''),
                                ),

                                // Employee
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(record.fullName ?? ''),
                                      Text(
                                        '${record.salaryAccount}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Salary Base
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.salary.toAmount(),
                                        style: textTheme.titleSmall,
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Base Hours
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${double.tryParse(record.hoursInMonth ?? '0')?.toStringAsFixed(1) ?? '0.0'} hr',
                                        style: textTheme.titleSmall,
                                      ),
                                      Text(
                                        record.calculationBase ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Worked Days
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${record.totalDays ?? 0} days',
                                        style: textTheme.titleSmall,
                                      ),
                                      Text(
                                        '${double.tryParse(record.workedHours ?? '0')?.toStringAsFixed(1) ?? '0.0'} hr',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Salary Payable
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.salaryPayable.toAmount(),
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Overtime
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.overtimePayable.toAmount(),
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Total Payable
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.totalPayable.toAmount(),
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        record.currency ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.outline.withValues(
                                            alpha: .7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status - Show visual status based on local changes
                                SizedBox(
                                  width: 105,
                                  child: StatusBadge(
                                    status: visualIsPaid ? 1 : 0,
                                    trueValue: tr.paidTitle,
                                    falseValue: tr.unpaidTitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    if (state is PayrollSilentLoadingState)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.surface,
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
}