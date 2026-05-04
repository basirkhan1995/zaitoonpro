import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
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
          return _ExpensesDialogContent(payments: state.expenses);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ExpensesDialogContent extends StatelessWidget {
  final List<PurchasePaymentRecord> payments;

  const _ExpensesDialogContent({required this.payments});

  @override
  Widget build(BuildContext context) {
    final totalExpenses = payments.fold(0.0, (sum, e) => sum + e.amount);
    final tr = AppLocalizations.of(context)!;
    String? baseCurrency;
    final authState = context.read<AuthBloc>().state;
    if(authState is AuthenticatedState){
     baseCurrency = authState.loginData.company?.comLocalCcy ?? "";
    }


    return ZFormDialog(
      title: tr.manageExpenses,
      icon: Icons.outbond_outlined,
      isActionTrue: false,
      padding: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width * .6,
      height: MediaQuery.of(context).size.width * .8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${tr.expenses} (${payments.length})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ZOutlineButton(
                onPressed: () {
                  context.read<PurchaseInvoiceBloc>().add(const AddPaymentEvent(isExpense: true));
                },
                icon: Icons.add,
                isActive: true,
                label: Text(tr.addItem),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expenses List
          Expanded(
            child: payments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No expenses added', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _ExpenseRow(
                  key: ValueKey(index),
                  index: index,
                  payment: payment,
                );
              },
            ),
          ),

          if (payments.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.totalExpense, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  "${totalExpenses.toAmount()} $baseCurrency",
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
      onAction: () => Navigator.pop(context),
    );
  }
}

class _ExpenseRow extends StatefulWidget {
  final int index;
  final PurchasePaymentRecord payment;

  const _ExpenseRow({
    required this.index,
    required this.payment,
    super.key,
  });

  @override
  State<_ExpenseRow> createState() => _ExpenseRowState();
}

class _ExpenseRowState extends State<_ExpenseRow> {
  late TextEditingController _narrationController;
  late TextEditingController _amountController;
  late TextEditingController _accountController;

  Timer? _debounce;
  bool _isUpdating = false;

  String? baseCurrency;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      baseCurrency = authState.loginData.company?.comLocalCcy;
    }

    _narrationController = TextEditingController(text: widget.payment.narration ?? '');
    _amountController = TextEditingController(
      text: widget.payment.amount > 0 ? widget.payment.amount.toString() : '',
    );
    _accountController = TextEditingController(
      text: _getAccountDisplayText(),
    );
  }

  String _getAccountDisplayText() {
    if (widget.payment.accountNumber != 0) {
      return widget.payment.accountNumber.toString();
    }
    return '';
  }

  @override
  void didUpdateWidget(_ExpenseRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isUpdating) return;

    // Narration
    final newNarration = widget.payment.narration ?? '';
    if (_narrationController.text != newNarration) {
      _narrationController.value = TextEditingValue(
        text: newNarration,
        selection: TextSelection.collapsed(offset: newNarration.length),
      );
    }

    // Amount
    final newAmount = widget.payment.amount > 0 ? widget.payment.amount.toString() : '';
    if (_amountController.text != newAmount) {
      _amountController.value = TextEditingValue(
        text: newAmount,
        selection: TextSelection.collapsed(offset: newAmount.length),
      );
    }

    // Account
    final newAccountText = _getAccountDisplayText();
    if (_accountController.text != newAccountText) {
      _accountController.text = newAccountText;
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
    int? accountNumber,
    double? exRate,
    String? currency,
  }) {
    _isUpdating = true;
    context.read<PurchaseInvoiceBloc>().add(
      UpdatePaymentEvent(
        index: widget.index,
        narration: narration,
        amount: amount,
        accountNumber: accountNumber,
        exRate: exRate ?? widget.payment.exRate,
        currency: currency ?? widget.payment.currency,
        isExpense: true,
      ),
    );

    Future.microtask(() {
      if (mounted) _isUpdating = false;
    });
  }
  void _debounceUpdate(VoidCallback action) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), action);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [
            /// Account Selection
            Expanded(
              flex: 2,
              child: GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                title: "",
                textFieldStyle: TextFieldStyle.noBorder,
                hintText: tr.accounts,
                controller: _accountController,
                bloc: context.read<AccountsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(
                  LoadAccountsFilterEvent(
                    include: "11,12", // Expense account types
                    ccy: baseCurrency,
                    exclude: "",
                  ),
                ),
                searchFunction: (bloc, query) => bloc.add(
                  LoadAccountsFilterEvent(
                    include: "11,12",
                    ccy: baseCurrency,
                    input: query,
                    exclude: "",
                  ),
                ),
                itemBuilder: (context, account) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Text(
                    "${account.accNumber} | ${account.accName}",
                  ),
                ),
                itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                stateToLoading: (state) => state is AccountLoadingState,
                stateToItems: (state) {
                  if (state is AccountLoadedState) {
                    return state.accounts;
                  }
                  return [];
                },
                onSelected: (account) {
                  _updateExpense(
                    accountNumber: account.accNumber,
                    currency: account.actCurrency ?? baseCurrency ?? '',
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
                decoration: InputDecoration(
                  hintText: tr.narration,
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: tr.amount,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  _debounceUpdate(() {
                    final amount = double.tryParse(value.replaceAll(',', '')) ?? 0;
                    _updateExpense(amount: amount);
                  });
                },
              ),
            ),

            /// Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () {
                context.read<PurchaseInvoiceBloc>().add(
                  RemovePaymentEvent(widget.index, wasExpense: true),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}