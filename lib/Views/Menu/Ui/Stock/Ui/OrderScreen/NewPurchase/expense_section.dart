import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Other/zForm_dialog.dart';
import '../../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'bloc/purchase_invoice_bloc.dart';
import 'model/purchase_invoice_items.dart';

class ExpensesDialog extends StatelessWidget {
  const ExpensesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
      builder: (context, state) {
        if (state is PurchaseInvoiceLoaded) {
          return _ExpensesDialogContent(expenses: state.expenses);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ExpensesDialogContent extends StatelessWidget {
  final List<PurExpenseRecord> expenses;

  const _ExpensesDialogContent({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return ZFormDialog(
      title: 'Manage Expenses',
      icon: Icons.outbond_outlined,
      isActionTrue: false,
      padding: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width * .65,
      height: MediaQuery.of(context).size.width * .8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ZOutlineButton(
                onPressed: () {
                  context.read<PurchaseInvoiceBloc>().add(AddExpenseEvent());
                },
                icon: Icons.add,
                isActive: true,
                label: const Text('Add Expense'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expenses List - Show empty state if no expenses
          Expanded(
            child: expenses.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses added',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Add Expense" to add expenses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return _ExpenseRow(
                  key: ValueKey(expense.rowId),
                  expense: expense,
                );
              },
            ),
          ),

          // Only show total and divider if there are expenses
          if (expenses.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Expenses:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  totalExpenses.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      onAction: () {
        Navigator.pop(context);
      },
    );
  }
}

class _ExpenseRow extends StatefulWidget {
  final PurExpenseRecord expense;

  const _ExpenseRow({required this.expense, super.key});

  @override
  State<_ExpenseRow> createState() => _ExpenseRowState();
}

class _ExpenseRowState extends State<_ExpenseRow> {
  late TextEditingController _narrationController;
  late TextEditingController _amountController;
  late TextEditingController _accountController;

  Timer? _debounce;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _narrationController =
        TextEditingController(text: widget.expense.narration);

    _amountController = TextEditingController(
      text: widget.expense.amount > 0
          ? widget.expense.amount.toString()
          : '',
    );

    _accountController =
        TextEditingController(text: widget.expense.accountName);
  }

  @override
  void didUpdateWidget(_ExpenseRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isUpdating) return;

    // Narration (ONLY update if different)
    if (_narrationController.text != widget.expense.narration) {
      _narrationController.value = TextEditingValue(
        text: widget.expense.narration,
        selection: TextSelection.collapsed(
          offset: widget.expense.narration.length,
        ),
      );
    }

    // Amount
    final newAmount =
    widget.expense.amount > 0 ? widget.expense.amount.toString() : '';

    if (_amountController.text != newAmount) {
      _amountController.value = TextEditingValue(
        text: newAmount,
        selection: TextSelection.collapsed(
          offset: newAmount.length,
        ),
      );
    }

    // Account
    if (_accountController.text != widget.expense.accountName) {
      _accountController.text = widget.expense.accountName;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _narrationController.dispose();
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _updateExpense({
    String? narration,
    double? amount,
    int? account,
    String? accountName,
  }) {
    _isUpdating = true;

    context.read<PurchaseInvoiceBloc>().add(
      UpdateExpenseEvent(
        rowId: widget.expense.rowId,
        narration: narration,
        amount: amount,
        account: account,
        accountName: accountName,
      ),
    );

    Future.microtask(() {
      if (mounted) _isUpdating = false;
    });
  }

  // ✅ Debounce handler
  void _debounceUpdate(VoidCallback action) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), action);
  }

  @override
  Widget build(BuildContext context) {
    return ZCover(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            /// Account
            Expanded(
              flex: 2,
              child: GenericTextfield<AccountsModel, AccountsBloc,
                  AccountsState>(
                title: "",
                textFieldStyle: TextFieldStyle.noBorder,
                hintText: AppLocalizations.of(context)!.accounts,
                controller: _accountController,
                bloc: context.read<AccountsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(
                  LoadAccountsFilterEvent(
                      include: "11,12", ccy: "USD", exclude: ""),
                ),
                searchFunction: (bloc, query) => bloc.add(
                  LoadAccountsFilterEvent(
                    include: "11,12",
                    ccy: "USD",
                    input: query,
                    exclude: "",
                  ),
                ),
                itemBuilder: (context, account) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 5),
                  child: Text(
                    "${account.accNumber} | ${account.accName}",
                  ),
                ),
                itemToString: (acc) =>
                "${acc.accNumber} | ${acc.accName}",
                stateToLoading: (state) =>
                state is AccountLoadingState,
                stateToItems: (state) {
                  if (state is AccountLoadedState) {
                    return state.accounts;
                  }
                  return [];
                },
                onSelected: (account) {
                  _updateExpense(
                    account: account.accNumber,
                    accountName:
                    '${account.accName} (${account.accNumber})',
                  );
                },
                showClearButton: true,
              ),
            ),

            const SizedBox(width: 8),

            /// Narration
            Expanded(
              flex: 2,
              child: TextField(
                controller: _narrationController,
                decoration: const InputDecoration(
                  hintText: 'Narration',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  _debounceUpdate(() {
                    _updateExpense(narration: value);
                  });
                },
              ),
            ),

            const SizedBox(width: 8),

            /// Amount
            Expanded(
              flex: 1,
              child: TextField(
                controller: _amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  _debounceUpdate(() {
                    final amount = double.tryParse(
                        value.replaceAll(',', '')) ??
                        0;
                    _updateExpense(amount: amount);
                  });
                },
              ),
            ),

            /// Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () {
                context.read<PurchaseInvoiceBloc>().add(
                  RemoveExpenseEvent(widget.expense.rowId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}