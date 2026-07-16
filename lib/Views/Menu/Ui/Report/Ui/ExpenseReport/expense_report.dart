import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import '../../../../../../../Features/Date/z_range_picker.dart';
import '../../../../../../Features/Other/zForm_dialog.dart';
import 'bloc/expense_report_bloc.dart';
import 'exp_report_model.dart';

class ExpenseReportView extends StatefulWidget {
  const ExpenseReportView({super.key});

  @override
  State<ExpenseReportView> createState() => _ExpenseReportViewState();
}

class _ExpenseReportViewState extends State<ExpenseReportView> {
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.expenses,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actionsPadding: EdgeInsets.all(8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<ExpenseReportBloc>().add(const RefreshExpenseReport());
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<ExpenseReportBloc, ExpenseReportState>(
        builder: (context, state) {
          if (state is ExpenseReportInitial) {
            context.read<ExpenseReportBloc>().add(const FetchExpenseReport());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExpenseReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExpenseReportError) {
            return _buildErrorState(context, state.message);
          }

          if (state is ExpenseReportLoaded) {
            final report = state.expenseReport;

            if (report.data.isEmpty) {
              return _buildEmptyState(context, state);
            }

            return Column(
              children: [
                // Compact Summary Card
                if (report.summary.isNotEmpty)
                  _buildCompactSummary(context, report.summary.first),

                // Filter chips
                if (state.dateFrom != null ||
                    state.dateTo != null ||
                    state.currency != null ||
                    state.accountNumber != null)
                  _buildFilterChips(context, state),

                // Expense List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: report.data.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = report.data[index];
                      return _buildCompactExpenseCard(context, expense);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<ExpenseReportBloc>().add(const RefreshExpenseReport()),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ExpenseReportLoaded state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No Expenses Found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Try adjusting your filters',
                style: TextStyle(color: Colors.grey[600])),
            if (state.dateFrom != null || state.currency != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.read<ExpenseReportBloc>().add(const ClearExpenseReportFilters()),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummary(BuildContext context, Summary summary) {
    final theme = Theme.of(context);
    final tr = AppLocalizations.of(context)!;

    return ZCover(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Title and Currency badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.totalExpense,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  summary.currency,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total Amount
          Text(
            '\$${_formatAmount(summary.totalAmount)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 14),

          // Stats row with dividers
          Row(
            children: [
              _buildStatItem(
                label: '${summary.transactionCount}',
                subtitle: tr.transactions,
                icon: Icons.receipt,
              ),
              _buildDivider(context),
              _buildStatItem(
                label: '\$${_formatAmount(summary.avgAmount)}',
                subtitle: tr.averageTitle,
                icon: Icons.equalizer,
              ),
              _buildDivider(context),
              _buildStatItem(
                label: '\$${_formatAmount(summary.minAmount)}',
                subtitle: "Min",
                icon: Icons.arrow_downward,
              ),
              _buildDivider(context),
              _buildStatItem(
                label: '\$${_formatAmount(summary.maxAmount)}',
                subtitle: "Max",
                icon: Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.4),
                size: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildFilterChips(BuildContext context, ExpenseReportLoaded state) {
    final List<Widget> chips = [];

    void addChip(String label, VoidCallback onDelete) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InputChip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          onDeleted: onDelete,
          backgroundColor: Colors.grey[100],
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ));
    }

    if (state.dateFrom != null && state.dateTo != null) {
      addChip('${state.dateFrom} → ${state.dateTo}', () {
        context.read<ExpenseReportBloc>().add(FilterExpenseReport(
            dateFrom: null, dateTo: null, currency: state.currency, accountNumber: state.accountNumber));
      });
    } else if (state.dateFrom != null) {
      addChip('From: ${state.dateFrom}', () {
        context.read<ExpenseReportBloc>().add(FilterExpenseReport(
            dateFrom: null, dateTo: state.dateTo, currency: state.currency, accountNumber: state.accountNumber));
      });
    } else if (state.dateTo != null) {
      addChip('To: ${state.dateTo}', () {
        context.read<ExpenseReportBloc>().add(FilterExpenseReport(
            dateFrom: state.dateFrom, dateTo: null, currency: state.currency, accountNumber: state.accountNumber));
      });
    }

    if (state.currency != null) {
      addChip(state.currency!, () {
        context.read<ExpenseReportBloc>().add(FilterExpenseReport(
            dateFrom: state.dateFrom, dateTo: state.dateTo, currency: null, accountNumber: state.accountNumber));
      });
    }

    if (state.accountNumber != null) {
      addChip('Acc: ${state.accountNumber}', () {
        context.read<ExpenseReportBloc>().add(FilterExpenseReport(
            dateFrom: state.dateFrom, dateTo: state.dateTo, currency: state.currency, accountNumber: null));
      });
    }

    if (chips.isNotEmpty) {
      chips.add(ActionChip(
        label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red)),
        backgroundColor: Colors.red[50],
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        onPressed: () => context.read<ExpenseReportBloc>().add(const ClearExpenseReportFilters()),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(spacing: 4, runSpacing: 4, children: chips),
    );
  }

  Widget _buildCompactExpenseCard(BuildContext context, ExpenseRecord expense) {
    final theme = Theme.of(context);
    final isAuthorized = expense.status == 'Authorized';
    final statusColor = isAuthorized ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showExpenseDetails(context, expense),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Left indicator
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                // Middle content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(expense.narration,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.grey[800]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMiniChip(expense.accountName, Colors.blue),
                          const SizedBox(width: 6),
                          _buildMiniChip(expense.expenseCategory, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${expense.maker} • ${expense.reference}',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500], fontSize: 10)),
                    ],
                  ),
                ),
                // Right side
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${expense.expenseAmount.toAmount()} ${expense.currency}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 15)),

                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(expense.status,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor[700])),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final bloc = context.read<ExpenseReportBloc>();
    final currentState = bloc.state;
    final tr = AppLocalizations.of(context)!;
    String? dateFrom;
    String? dateTo;
    String? currency;
    int? accountNumber;

    if (currentState is ExpenseReportLoaded) {
      dateFrom = currentState.dateFrom;
      dateTo = currentState.dateTo;
      currency = currentState.currency;
      accountNumber = currentState.accountNumber;
    }

    showDialog(
      context: context,
      builder: (context) {
        return ZFormDialog(
          width: 500,
          padding: EdgeInsets.all(12),
          onAction: () {},
          isActionTrue: false,
          title: tr.filterTitle,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZRangeDatePicker(
                  label: tr.selectDate,
                  initialStartDate: DateTime.tryParse(dateFrom ?? ""),
                  initialEndDate: DateTime.tryParse(dateTo ?? ""),
                  startValue: dateFrom,
                  endValue: dateTo,
                  onStartDateChanged: (startDate) {
                    dateFrom = startDate;
                    // Update state if needed
                  },
                  onEndDateChanged: (endDate) {
                    dateTo = endDate;
                    // Update state if needed
                  },
                  minYear: 2000,
                  maxYear: 2100,
                ),
                const SizedBox(height: 8),
                ZTextFieldEntitled(
                  title: tr.accountNumber,
                  hint: tr.accountNumber,
                  onChanged: (value) {
                    accountNumber = int.tryParse(value);
                  },
                ),
                const SizedBox(height: 8),
                CurrencyDropdown(
                  title: tr.currencyTitle,
                  onSingleChanged: (e) {
                    currency = e?.ccyCode;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ZOutlineButton(
                        onPressed: () {
                          Navigator.pop(context);
                          bloc.add(const ClearExpenseReportFilters());
                        },
                        label: Text(tr.clearFilters),
                        backgroundHover: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ZOutlineButton(
                        isActive: true,
                        onPressed: () {
                          Navigator.pop(context);
                          bloc.add(FilterExpenseReport(
                            dateFrom: dateFrom,
                            dateTo: dateTo,
                            currency: currency,
                            accountNumber: accountNumber,
                          ));
                        },
                        label: Text(tr.applyFilter),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showExpenseDetails(BuildContext context, ExpenseRecord expense) {
    final isAuthorized = expense.status == 'Authorized';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(expense.narration,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAuthorized ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(expense.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: isAuthorized ? Colors.green[700] : Colors.orange[700])),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Amount', '${expense.expenseAmount} ${expense.currency}'),
              _detailRow('USD Equivalent', '\$${expense.usdEquivalent}'),
              _detailRow('Reference', expense.reference),
              _detailRow('Date', expense.transactionDate?.toString() ?? 'N/A'),
              _detailRow('Account', '${expense.accountName} (${expense.accountNumber})'),
              _detailRow('Category', expense.expenseCategory),
              _detailRow('Branch', expense.branch),
              _detailRow('Maker', expense.maker),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(String amount) {
    try {
      return double.parse(amount).toStringAsFixed(2);
    } catch (e) {
      return amount;
    }
  }
}