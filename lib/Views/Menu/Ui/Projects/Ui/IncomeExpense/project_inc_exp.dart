import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/toast.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Features/Widgets/txn_status_widget.dart';
import 'package:zaitoon_petroleum/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/Ui/IncomeExpense/bloc/project_inc_exp_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/Ui/IncomeExpense/model/prj_inc_exp_model.dart';

import 'add_edit_inc_exp.dart';

class ProjectIncomeExpenseView extends StatelessWidget {
  final ProjectsModel? project;
  const ProjectIncomeExpenseView({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(project),
      tablet: _Tablet(project),
      desktop: _Desktop(project),
    );
  }
}

class _Mobile extends StatefulWidget {
  final ProjectsModel? project;
  const _Mobile(this.project);

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  String? myLocale;

  @override
  void initState() {
    super.initState();
    myLocale = context.read<LocalizationBloc>().state.languageCode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.project?.prjId != null) {
        context.read<ProjectIncExpBloc>().add(
          LoadProjectIncExpEvent(widget.project!.prjId!),
        );
      }
    });
  }

  void _showAddTransactionDialog() {
    if (widget.project == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEditIncomeExpenseDialog(
        project: widget.project!,
      ),
    );
  }

  void _showEditTransactionDialog(Payment payment) {
    if (widget.project == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEditIncomeExpenseDialog(
        project: widget.project!,
        existingData: payment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionDialog,
          child: Icon(Icons.add)),
      body: BlocConsumer<ProjectIncExpBloc, ProjectIncExpState>(
        listener: (context, state) {
          if (state is ProjectIncExpErrorState) {
            ToastManager.show(
              context: context,
              title: tr.errorTitle,
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is ProjectIncExpSuccessState) {
            ToastManager.show(
              context: context,
              title: tr.successTitle,
              message: tr.successMessage,
              type: ToastType.success,
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectIncExpLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectIncExpErrorState) {
            return NoDataWidget(
              title: tr.errorTitle,
              message: state.message,
              onRefresh: () {
                if (widget.project?.prjId != null) {
                  context.read<ProjectIncExpBloc>().add(
                    LoadProjectIncExpEvent(widget.project!.prjId!),
                  );
                }
              },
            );
          }

          if (state is ProjectIncExpLoadedState) {
            final inOut = state.inOut;
            final payments = inOut.payments ?? [];

            // Calculate totals
            double totalIncome = 0;
            double totalExpense = 0;

            for (var payment in payments) {
              if (payment.prpType == 'Payment') {
                totalIncome += double.tryParse(payment.payments ?? '0') ?? 0;
              } else if (payment.prpType == 'Expense') {
                totalExpense += double.tryParse(payment.expenses ?? '0') ?? 0;
              }
            }

            final balance = totalIncome - totalExpense;
            final currency = inOut.trdCcy ?? widget.project?.actCurrency ?? '';

            if (payments.isEmpty) {
              return NoDataWidget(
                title: "No Transactions",
                message: "Tap + to add your first transaction",
                enableAction: false,
              );
            }

            return Column(
              children: [
                // Summary Cards - Horizontal scrollable on mobile
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      _buildMobileSummaryCard(
                        context,
                        title: tr.totalProjects,
                        amount: double.tryParse(inOut.totalProjectAmount ?? '0') ?? 0,
                        currency: currency,
                        color: color.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildMobileSummaryCard(
                        context,
                        title: tr.totalPayment,
                        amount: totalIncome,
                        currency: currency,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildMobileSummaryCard(
                        context,
                        title: tr.totalExpense,
                        amount: totalExpense,
                        currency: currency,
                        color: color.error,
                      ),
                      const SizedBox(width: 8),
                      _buildMobileSummaryCard(
                        context,
                        title: tr.balance,
                        amount: balance,
                        currency: currency,
                        color: balance >= 0 ? Colors.blue : Colors.orange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Transactions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final income = double.tryParse(payment.payments ?? '0') ?? 0;
                      final expense = double.tryParse(payment.expenses ?? '0') ?? 0;

                      return _buildMobileTransactionCard(
                        context,
                        payment: payment,
                        income: income,
                        expense: expense,
                        currency: currency,
                        onTap: widget.project?.prjStatus == 0
                            ? () => _showEditTransactionDialog(payment)
                            : null,
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
    );
  }

  Widget _buildMobileSummaryCard(
      BuildContext context, {
        required String title,
        required double amount,
        required String currency,
        required Color color,
      }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toAmount()} $currency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionCard(
      BuildContext context, {
        required Payment payment,
        required double income,
        required double expense,
        required String currency,
        required VoidCallback? onTap,
      }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: color.outline.withValues(alpha: .1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and reference
              Row(
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
                      payment.trnEntryDate != null
                          ? '${payment.trnEntryDate!.day}/${payment.trnEntryDate!.month}/${payment.trnEntryDate!.year}'
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payment.prpTrnRef ?? '',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TransactionStatusBadge(
                    status: payment.trnStateText ?? "",
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Type and amounts
              Row(
                children: [
                  // Type indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: payment.prpType == 'Payment'
                          ? Colors.green.withValues(alpha: .1)
                          : color.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          payment.prpType == 'Payment'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 12,
                          color: payment.prpType == 'Payment'
                              ? Colors.green
                              : color.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          payment.prpType == "Payment"
                              ? 'Income'
                              : payment.prpType == "Expense"
                              ? 'Expense'
                              : payment.prpType ?? "",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: payment.prpType == 'Payment'
                                ? Colors.green
                                : color.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Amount
                  if (income > 0)
                    Text(
                      '+ ${income.toAmount()} $currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  if (expense > 0)
                    Text(
                      '- ${expense.toAmount()} $currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.error,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  final ProjectsModel? project;
  const _Tablet(this.project);

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  String? myLocale;

  @override
  void initState() {
    super.initState();
    myLocale = context.read<LocalizationBloc>().state.languageCode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.project?.prjId != null) {
        context.read<ProjectIncExpBloc>().add(
          LoadProjectIncExpEvent(widget.project!.prjId!),
        );
      }
    });
  }

  void _showAddTransactionDialog() {
    if (widget.project == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEditIncomeExpenseDialog(
        project: widget.project!,
      ),
    );
  }

  void _showEditTransactionDialog(Payment payment) {
    if (widget.project == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEditIncomeExpenseDialog(
        project: widget.project!,
        existingData: payment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionDialog,
          child: Icon(Icons.add),
      ),
      body: BlocConsumer<ProjectIncExpBloc, ProjectIncExpState>(
        listener: (context, state) {
          if (state is ProjectIncExpErrorState) {
            ToastManager.show(
              context: context,
              title: tr.errorTitle,
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is ProjectIncExpSuccessState) {
            ToastManager.show(
              context: context,
              title: tr.successTitle,
              message: tr.successMessage,
              type: ToastType.success,
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectIncExpLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectIncExpErrorState) {
            return NoDataWidget(
              title: tr.errorTitle,
              message: state.message,
              onRefresh: () {
                if (widget.project?.prjId != null) {
                  context.read<ProjectIncExpBloc>().add(
                    LoadProjectIncExpEvent(widget.project!.prjId!),
                  );
                }
              },
            );
          }

          if (state is ProjectIncExpLoadedState) {
            final inOut = state.inOut;
            final payments = inOut.payments ?? [];

            // Calculate totals
            double totalIncome = 0;
            double totalExpense = 0;

            for (var payment in payments) {
              if (payment.prpType == 'Payment') {
                totalIncome += double.tryParse(payment.payments ?? '0') ?? 0;
              } else if (payment.prpType == 'Expense') {
                totalExpense += double.tryParse(payment.expenses ?? '0') ?? 0;
              }
            }

            final balance = totalIncome - totalExpense;
            final currency = inOut.trdCcy ?? widget.project?.actCurrency ?? '';

            if (payments.isEmpty) {
              return NoDataWidget(
                title: "No Transactions",
                message: "Click Add Transaction to create your first entry",
                enableAction: false,
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2,
                    children: [
                      _buildTabletSummaryCard(
                        context,
                        title: tr.totalProjects,
                        amount: double.tryParse(inOut.totalProjectAmount ?? '0') ?? 0,
                        currency: currency,
                        color: color.primary,
                      ),
                      _buildTabletSummaryCard(
                        context,
                        title: tr.totalPayment,
                        amount: totalIncome,
                        currency: currency,
                        color: Colors.green,
                      ),
                      _buildTabletSummaryCard(
                        context,
                        title: tr.totalExpense,
                        amount: totalExpense,
                        currency: currency,
                        color: color.error,
                      ),
                      _buildTabletSummaryCard(
                        context,
                        title: tr.balance,
                        amount: balance,
                        currency: currency,
                        color: balance >= 0 ? Colors.blue : Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Transactions Table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: color.outline.withValues(alpha: .2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: color.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(tr.date, style: titleStyle),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(tr.referenceNumber, style: titleStyle),
                              ),
                              Expanded(
                                child: Text(tr.payment, style: titleStyle),
                              ),
                              Expanded(
                                child: Text(tr.expense, style: titleStyle),
                              ),
                              Expanded(
                                child: Text(tr.status, style: titleStyle),
                              ),
                            ],
                          ),
                        ),

                        // List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            final income = double.tryParse(payment.payments ?? '0') ?? 0;
                            final expense = double.tryParse(payment.expenses ?? '0') ?? 0;

                            return InkWell(
                              onTap: widget.project?.prjStatus == 0
                                  ? () => _showEditTransactionDialog(payment)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: index.isOdd
                                      ? color.primary.withValues(alpha: .02)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: color.outline.withValues(alpha: .1),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        payment.trnEntryDate != null
                                            ? '${payment.trnEntryDate!.day}/${payment.trnEntryDate!.month}/${payment.trnEntryDate!.year}'
                                            : '',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            payment.prpTrnRef ?? '',
                                            style: textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            payment.prpType == "Payment"
                                                ? tr.payment
                                                : payment.prpType == "Expense"
                                                ? tr.expense
                                                : payment.prpType ?? "",
                                            style: textTheme.bodySmall?.copyWith(
                                              color: payment.prpType == 'Payment'
                                                  ? Colors.green
                                                  : color.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        income > 0 ? '${income.toAmount()} $currency' : '-',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        expense > 0 ? '${expense.toAmount()} $currency' : '-',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: color.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TransactionStatusBadge(
                                        status: payment.trnStateText ?? "",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildTabletSummaryCard(
      BuildContext context, {
        required String title,
        required double amount,
        required String currency,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${amount.toAmount()} $currency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  final ProjectsModel? project;
  const _Desktop(this.project);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  String? myLocale;

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.project?.prjId != null) {
        context.read<ProjectIncExpBloc>().add(
          LoadProjectIncExpEvent(widget.project!.prjId!),
        );
      }
    });
    super.initState();
  }

  void _showAddTransactionDialog() {
    if (widget.project == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEditIncomeExpenseDialog(
        project: widget.project!,
      ),
    );
  }

  void _showEditTransactionDialog(Payment payment) {
    if (widget.project == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEditIncomeExpenseDialog(
        project: widget.project!,
        existingData: payment, // Pass the Payment object
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: widget.project?.prjStatus == 0
          ? FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      )
          : null,
      body: BlocConsumer<ProjectIncExpBloc, ProjectIncExpState>(
        listener: (context, state) {
          if (state is ProjectIncExpErrorState) {
            ToastManager.show(
              context: context,
              title: tr.errorTitle,
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is ProjectIncExpSuccessState) {
            ToastManager.show(
              context: context,
              title: tr.successTitle,
              message: tr.successMessage,
              type: ToastType.success,
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectIncExpLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectIncExpErrorState) {
            return NoDataWidget(
              title: tr.errorTitle,
              message: state.message,
              onRefresh: () {
                if (widget.project?.prjId != null) {
                  context.read<ProjectIncExpBloc>().add(
                    LoadProjectIncExpEvent(widget.project!.prjId!),
                  );
                }
              },
            );
          }

          if (state is ProjectIncExpLoadedState) {
            final inOut = state.inOut;
            final payments = inOut.payments ?? [];

            // Calculate totals
            double totalIncome = 0;
            double totalExpense = 0;

            for (var payment in payments) {
              if (payment.prpType == 'Payment') {
                totalIncome += double.tryParse(payment.payments ?? '0') ?? 0;
              } else if (payment.prpType == 'Expense') {
                totalExpense += double.tryParse(payment.expenses ?? '0') ?? 0;
              }
            }

            final balance = totalIncome - totalExpense;
            final currency = inOut.trdCcy ?? widget.project?.actCurrency ?? '';

            if (payments.isEmpty) {
              return NoDataWidget(
                title: "No Transactions",
                message: "No income or expense records found",
                enableAction: false,
              );
            }

            return Column(
              children: [
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          title: tr.totalProjects,
                          amount: double.tryParse(inOut.totalProjectAmount ?? '0') ?? 0,
                          currency: currency,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          title: tr.totalPayment,
                          amount: totalIncome,
                          currency: currency,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          title: tr.totalExpense,
                          amount: totalExpense,
                          currency: currency,
                          color: color.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          title: tr.balance,
                          amount: balance,
                          currency: currency,
                          color: balance >= 0 ? Colors.blue : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.primary,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(tr.date, style: titleStyle),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(tr.referenceNumber, style: titleStyle),
                      ),
                      Expanded(
                        child: Text(
                          tr.payment,
                          style: titleStyle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tr.expense,
                          style: titleStyle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tr.status,
                          style: titleStyle,
                        ),
                      ),
                    ],
                  ),
                ),

                // List of Transactions
                Expanded(
                  child: ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final income = double.tryParse(payment.payments ?? '0') ?? 0;
                      final expense = double.tryParse(payment.expenses ?? '0') ?? 0;

                      return InkWell(
                        onTap: widget.project?.prjStatus == 0
                            ? () => _showEditTransactionDialog(payment)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: index.isOdd
                                ? color.primary.withValues(alpha: .05)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withValues(alpha: .2),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(
                                  payment.trnEntryDate != null
                                      ? '${payment.trnEntryDate!.day}/${payment.trnEntryDate!.month}/${payment.trnEntryDate!.year}'
                                      : '',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment.prpTrnRef ?? '',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      payment.prpType == "Payment"
                                          ? tr.payment
                                          : payment.prpType == "Expense"
                                          ? tr.expense
                                          : payment.prpType ?? "",
                                      style: textTheme.bodySmall?.copyWith(
                                        color: payment.prpType == 'Payment'
                                            ? Colors.green
                                            : color.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  income > 0 ? '${income.toAmount()} $currency' : '',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  expense > 0 ? '${expense.toAmount()} $currency' : '',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TransactionStatusBadge(status: payment.trnStateText ?? ""),
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
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required double amount,
        required String currency,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toAmount()} $currency',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}